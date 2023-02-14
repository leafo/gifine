
import Gtk from require "gifine.gtk"

class LoadWindow
  record_text: {
    recording: "Stop recording"
    standby: "Record rectangle"
  }

  new: =>
    @create!
    @window\show_all!

  open_preview_from_dir: (dir) =>
    import PreviewWindow from require "gifine.preview_window"
    @window\hide!
    preview = PreviewWindow!
    preview\set_frames_from_dir dir

  create: =>
    @window = Gtk.Window {
      title: "Record or load frames"
      border_width: 8
      default_width: 300
      default_height: 128

      on_destroy: ->
        return Gtk.main_quit!

      on_key_press_event: (win, e) ->
        if e.string\byte! == 27
          return Gtk.main_quit!

      Gtk.VBox {
        spacing: 8

        Gtk.Frame {
          Gtk.HBox {
            border_width: 8
            spacing: 4

            @create_record_button!

            Gtk.VBox {
              spacing: 2
              Gtk.SpinButton {
                id: "framerate_input"
                expand: true
                adjustment: Gtk.Adjustment {
                  lower: 1
                  upper: 80
                  value: 30
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

        Gtk.Frame {
          Gtk.VBox {
            spacing: 4
            border_width: 8

            Gtk.Label label: "Load directory of frames"
            Gtk.FileChooserButton {
              title: "Pick a Folder"
              action: "SELECT_FOLDER"
              on_file_set: (picker) ->
                folder = picker\get_filename!
                return unless folder
                @open_preview_from_dir folder
            }
          }
        }
      }

    }

  create_record_button: =>
    Gtk.Button {
      id: "record_button"
      label: @record_text.standby

      on_clicked: ->
        if @ffmpeg_process
          input = @ffmpeg_process\get_stdin_pipe!
          input\write "q"
          @ffmpeg_process\force_exit!
          return

        framerate = @window.child.framerate_input.adjustment.value
        framerate or= 30

        import Gio from require "lgi"
        import snap_frames_rect from require "gifine.commands"

        Gio.Async.start(->
          dir, err = snap_frames_rect framerate, (ffmpeg_process) ->
            @ffmpeg_process = ffmpeg_process
            @window.child.record_button.label = @record_text.recording

          unless dir
            if err == "missing command"
              @show_alert "Missing command", "You need either slop or xrectsel installed to select a rectangle to record. Check README.md for more information."

            return


          @ffmpeg_process = nil
          @window.child.record_button.label = @record_text.standby
          @open_preview_from_dir dir
        )!
    }

  show_alert: (title, text) =>
    dialog = Gtk.MessageDialog {
      text: title
      secondary_text: text
      message_type: Gtk.MessageType.ERROR
      buttons: Gtk.ButtonsType.CLOSE
      transient_for: @window
    }

    dialog\run!
    dialog\destroy!



{:LoadWindow}


