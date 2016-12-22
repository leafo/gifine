
import Gtk from require "lgi"

class LoadWindow
  record_text: {
    recording: "Stop recording"
    standby: "Record rectange"
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
      default_width: 256
      default_height: 256

      on_destroy: ->
        return Gtk.main_quit!

      on_key_press_event: (win, e) ->
        if e.string\byte! == 27
          return Gtk.main_quit!

      Gtk.VBox {
        spacing: 4
        Gtk.Button {
          id: "record_button"
          label: @record_text.standby

          on_clicked: ->
            if @ffmpeg_process
              @ffmpeg_process\force_exit!
              return

            import Gio from require "lgi"
            import snap_frames_rect from require "gifine.commands"

            Gio.Async.start(->
              dir = snap_frames_rect (ffmpeg_process) ->
                @ffmpeg_process = ffmpeg_process
                @window.child.record_button.label = @record_text.recording

              @ffmpeg_process = nil
              @window.child.record_button.label = @record_text.standby
              @open_preview_from_dir dir
            )!
        }
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



{:LoadWindow}


