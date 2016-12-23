import Gtk from require "lgi"

import async_command from require "gifine.commands"

class PreviewWindow
  new: =>
    @create!
    @window\show_all!
    @set_status "Ready"

  set_status: (msg) =>
    statusbar = @window.child.statusbar
    ctx = statusbar\get_context_id "default"
    statusbar\push ctx, msg

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
      @set_status "Loaded #{dir}"

  create: =>
    @window = Gtk.Window {
      title: "Preview"
      default_width: 256
      default_height: 256

      on_destroy: ->
        return Gtk.main_quit!

      on_key_press_event: (win, e) ->
        if e.string\byte! == 27
          return Gtk.main_quit!

      Gtk.VBox {
        Gtk.VBox {
          spacing: 4
          border_width: 8

          Gtk.Image {
            id: "current_image"
            file: "hi.png"
            expand: true
          }

          @create_scrubber!
          @create_gif_export!
          @create_video_export!
        }

        Gtk.Statusbar {
          id: "statusbar"
        }
      }
    }


  create_video_export: =>
    Gtk.Frame {
      label: "Encode video"

      Gtk.HBox {
        spacing: 4
        border_width: 8

        Gtk.Button {
          label: "Save MP4..."
          on_clicked: (btn) ->
            import Gio from require "lgi"
            import make_mp4 from require "gifine.commands"

            save_to = @choose_save_file!
            return unless save_to

            btn.sensitive = false
            framerate = @window.child.framerate_input.adjustment.value

            Gio.Async.start(->
              out_fname = make_mp4 @loaded_frames, {
                fname: save_to
                :framerate
                progress_fn: (step) ->
                  @set_status "Working: #{step}"
              }

              @set_status "Wrote mp4 to #{out_fname}"
              btn.sensitive = true
            )!


        }

        Gtk.VBox {
          spacing: 2
          Gtk.SpinButton {
            id: "framerate_input"
            expand: true
            adjustment: Gtk.Adjustment {
              lower: 10
              upper: 120
              value: 60
              page_size: 1
              step_increment: 1
            }
          }
          Gtk.Label {
            label: "Framerate"
          }
        }

      }
    }


  create_gif_export: =>
    Gtk.Frame {
      label: "Encode GIF"

      Gtk.HBox {
        spacing: 4
        border_width: 8

        Gtk.Button {
          label: "Save GIF..."
          on_clicked: (btn) ->
            import Gio from require "lgi"
            import make_gif from require "gifine.commands"

            save_to = @choose_save_file!
            return unless save_to

            btn.sensitive = false

            delay = @window.child.delay_input.adjustment.value

            Gio.Async.start(->
              out_fname = make_gif @loaded_frames, {
                fname: save_to
                :delay
                progress_fn: (step) ->
                  @set_status "Working: #{step}"
              }

              @set_status "Wrote gif to #{out_fname}"
              btn.sensitive = true
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
    }

  create_scrubber: =>
    Gtk.HBox {
      spacing: 4
      Gtk.Button {
        label: "Trim left of"
      }

      Gtk.HScale {
        id: "image_scroller"
        expand: true

        round_digits: 0
        digits: 0

        on_value_changed: (scroller) ->
          value = scroller.adjustment.value
          value = math.floor value + 0.5
          return unless @loaded_frames
          @current_frame_idx = value
          frame = @loaded_frames[value]

          @window.child.current_image.file = frame

        adjustment: Gtk.Adjustment {
          lower: 0
          upper: 100
          value: 50
          page_size: 1
          step_increment: 1
        }
      }

      Gtk.Button {
        label: "Trim right of"
      }

      Gtk.Button {
        label: "Delete frame"
      }
    }

  choose_save_file: =>
    local save_to

    dialog = Gtk.FileChooserDialog {
      title: "Save to GIF"
      action: Gtk.FileChooserAction.SAVE
      transient_for: @window
      buttons: {
        { Gtk.STOCK_SAVE, Gtk.ResponseType.ACCEPT }
        { Gtk.STOCK_CLOSE, Gtk.ResponseType.CANCEL }
      }

      on_response: (dialog, response) ->
        switch response
          when Gtk.ResponseType.ACCEPT
            save_to = dialog\get_filename!
          when Gtk.ResponseType.CANCEL
            nil
    }

    dialog\run!
    dialog\destroy!
    save_to

{:PreviewWindow}
