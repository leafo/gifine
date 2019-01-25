import Gtk from require "lgi"

import async_command from require "gifine.commands"

class PreviewWindow
  loaded_frames: nil
  working_frames: nil

  new: =>
    @create!
    @window\show_all!
    @set_status "Ready"

  show_frame: (idx) =>
    return unless @current_frames
    @current_frame_idx = idx
    frame = @current_frames[@current_frame_idx]
    @window.child.current_image.file = frame

  refresh_adjustment: =>
    with @window.child.image_scroller.adjustment
      .lower = 1
      .upper = #@current_frames + 1

      -- make sure the idx is still within range
      if @current_frame_idx
        idx = math.max .lower, math.min @current_frame_idx, .upper
        if idx != @current_frame_idx
          .value = idx

  reset_frames: =>
    return unless @loaded_frames
    @current_frames = [f for f in *@loaded_frames]

    adjustment = @refresh_adjustment!
    adjustment.value = 1

  halve_frames: =>
    return if #@current_frames == 1
    @current_frames = [frame for idx, frame in ipairs @current_frames when idx % 2 == (@current_frame_idx % 2)]
    new_idx = math.min #@current_frames, math.max 1, math.floor @current_frame_idx / 2

    adjustment = @refresh_adjustment!
    adjustment.value = new_idx

  trim_left_of: =>
    return if not @current_frame_idx or @current_frame_idx == 1
    @current_frames = [frame for idx, frame in ipairs @current_frames when idx >= @current_frame_idx]

    adjustment = @refresh_adjustment!
    adjustment.value = 1

  trim_right_of: =>
    return if not @current_frame_idx or @current_frame_idx == #@current_frames
    @current_frames = [frame for idx, frame in ipairs @current_frames when idx <= @current_frame_idx]
    @refresh_adjustment!

  delete_current_frame: =>
    return if not @current_frame_idx or #@current_frames == 0

    @current_frames = [frame for idx, frame in ipairs @current_frames when idx != @current_frame_idx]

    adjustment = @refresh_adjustment!
    @show_frame @current_frame_idx

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
      @reset_frames!

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

      Gtk.Box {
        orientation: "VERTICAL"
        Gtk.Box {
          orientation: "VERTICAL"
          spacing: 4
          border_width: 8
          expand: true

          Gtk.ScrolledWindow {
            expand: true
            min_content_height: 400
            min_content_width: 400

            Gtk.Viewport {
              Gtk.Image {
                id: "current_image"
              }
            }
          }

          @create_scrubber!
          @create_frame_tools!
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
      expand: false

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
            loop = @window.child.loop_input.adjustment.value

            Gio.Async.start(->
              out_fname, size = make_mp4 @current_frames, {
                fname: save_to
                :framerate
                :loop
                progress_fn: (step) ->
                  @set_status "Working: #{step}"
              }

              @set_status "Wrote mp4 to #{out_fname} (#{size})"
              btn.sensitive = true
            )!


        }

        Gtk.Box {
          orientation: "VERTICAL"
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

        Gtk.Box {
          orientation: "VERTICAL"
          spacing: 2

          Gtk.SpinButton {
            id: "loop_input"
            expand: true
            adjustment: Gtk.Adjustment {
              lower: 1
              upper: 100
              value: 1
              page_size: 1
              step_increment: 1
            }
          }
          Gtk.Label {
            label: "Loop"
          }
        }


      }
    }


  create_gif_export: =>
    Gtk.Frame {
      label: "Encode GIF"
      expand: false

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
              out_fname, size = make_gif @current_frames, {
                fname: save_to
                :delay
                progress_fn: (step) ->
                  @set_status "Working: #{step}"
              }

              @set_status "Wrote gif to #{out_fname} (#{size})"
              btn.sensitive = true
            )!
        }

        Gtk.Box {
          orientation: "VERTICAL"
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
    Gtk.HScale {
      id: "image_scroller"

      round_digits: 0
      digits: 0

      on_value_changed: (scroller) ->
        value = scroller.adjustment.value
        idx = math.floor value + 0.5
        @show_frame idx

      adjustment: Gtk.Adjustment {
        lower: 0
        upper: 100
        value: 50
        page_size: 1
        step_increment: 1
      }
    }

  create_frame_tools: =>
    Gtk.HBox {
      spacing: 4
      Gtk.Button {
        label: "Trim left of"
        on_clicked: -> @trim_left_of!
      }

      Gtk.Button {
        label: "Trim right of"
        on_clicked: -> @trim_right_of!
      }

      Gtk.Button {
        label: "Delete frame"
        on_clicked: -> @delete_current_frame!
      }

      Gtk.Button {
        label: "Halve frames"
        on_clicked: -> @halve_frames!
      }

      Gtk.Button {
        label: "Reset cuts"
        on_clicked: -> @reset_frames!
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
