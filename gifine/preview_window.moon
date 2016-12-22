import Gtk from require "lgi"

import async_command from require "gifine.commands"

class PreviewWindow
  new: =>
    @create!
    @window\show_all!

  set_frames_from_dir: (dir) =>
    async_command {"find", dir, "-maxdepth", "1"}, (res) ->
      fnames = for fname in res\gmatch "([^\n]+)"
        continue unless fname\match "%.png$"
        fname

      table.sort fnames
      @loaded_frames = fnames

      adjustment = @window.child.image_scroller.adjustment
      adjustment.lower = 1
      adjustment.upper = #fnames + 1
      adjustment.value = 1

  create: =>
    @window = Gtk.Window {
      title: "Preview"
      border_width: 8
      default_width: 256
      default_height: 256

      on_destroy: ->
        return Gtk.main_quit!

      on_key_press_event: (win, e) ->
        if e.string\byte! == 27
          return Gtk.main_quit!

      Gtk.VBox {
        spacing: 4
        Gtk.Image {
          id: "current_image"
          file: "hi.png"
          expand: true
        }

        @create_scrubber!
        @create_action_buttons!
      }
    }

  create_action_buttons: =>
    default_label = "Encode GIF"

    Gtk.HBox {
      spacing: 4
      Gtk.Button {
        label: default_label
        on_clicked: (btn) ->
          import Gio from require "lgi"
          import make_gif from require "gifine.commands"

          btn.sensitive = false

          delay = @window.child.delay_input.adjustment.value

          Gio.Async.start(->
            out_fname = make_gif @loaded_frames, {
              :delay
              progress_fn: (step) ->
                btn.label = "Working: #{step}"
            }

            print "Wrote gif to", out_fname
            btn.sensitive = true
            btn.label = default_label
          )!
      }

      Gtk.VBox {
        spacing: 2
        Gtk.SpinButton {
          id: "delay_input"
          expand: true
          adjustment: Gtk.Adjustment {
            lower: 1
            upper: 10
            value: 2
            page_size: 1
            step_increment: 1
          }
        }
        Gtk.Label {
          label: "Delay"
        }
      }

    }


  create_scrubber: =>
    Gtk.HBox {
      spacing: 4
      Gtk.HScrollbar {
        id: "image_scroller"
        expand: true

        on_value_changed: (scroller) ->
          value = scroller.adjustment.value
          value = math.floor value + 0.5
          return unless @loaded_frames
          frame = @loaded_frames[value]
          print "setting frame", frame, value
          @window.child.current_image.file = frame
          @window.child.current_frame_label.label = "#{value}"

        adjustment: Gtk.Adjustment {
          lower: 0
          upper: 100
          value: 50
          page_size: 1
          step_increment: 1
        }
      }

      Gtk.Label {
        id: "current_frame_label"
        label: "Standby"
      }
    }


{:PreviewWindow}
