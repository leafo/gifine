import Gtk, GLib from require "lgi"

import async_command from require "gifine.commands"

local loaded_frames
local window

window = Gtk.Window {
  title: "Preview"
  border_width: 8
  default_width: 256
  default_height: 256

  on_destroy: =>
    return Gtk.main_quit!

  on_key_press_event: (e) =>
    if e.string\byte! == 27
      return Gtk.main_quit!

  Gtk.VBox {
    spacing: 4
    Gtk.Image {
      id: "current_image"
      file: "hi.png"
      expand: true
    }

    Gtk.HBox {
      spacing: 4
      Gtk.HScrollbar {
        id: "image_scroller"
        expand: true

        on_value_changed: =>
          value = @adjustment.value
          value = math.floor value + 0.5
          return unless loaded_frames
          frame = loaded_frames[value]
          print "setting frame", frame, value
          window.child.current_image.file = frame
          window.child.current_frame_label.label = "#{value}"

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

    Gtk.HBox {
      spacing: 4
      Gtk.Button {
        label: "Load images"

        on_clicked: =>
          async_command {"find", "frames/"}, (res) ->
            fnames = for fname in res\gmatch "([^\n]+)"
              continue unless fname\match "%.png$"
              fname

            table.sort fnames
            loaded_frames = fnames

            adjustment = window.child.image_scroller.adjustment
            adjustment.lower = 1
            adjustment.upper = #fnames + 1
            adjustment.value = 1
      }

      Gtk.FileChooserButton {
        title: "Pick a Folder"
        action: "SELECT_FOLDER"
        on_file_set: (picker) ->
          folder = picker\get_filename!
          return unless folder

          async_command {"find", folder, "-maxdepth", "1"}, (res) ->
            fnames = for fname in res\gmatch "([^\n]+)"
              continue unless fname\match "%.png$"
              fname

            table.sort fnames
            loaded_frames = fnames

            adjustment = window.child.image_scroller.adjustment
            adjustment.lower = 1
            adjustment.upper = #fnames + 1
            adjustment.value = 1
      }
    }

  }
}

window\show_all!

Gtk.main!
