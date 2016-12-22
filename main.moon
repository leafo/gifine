

import Gtk, Gio, GLib from require "lgi"

async_command = (argv, callback) ->
  Gio.Async.start(->
    process = Gio.Subprocess {
      :argv
      flags: {"STDOUT_PIPE"}
    }

    pipe = process\get_stdout_pipe!
    buffer = {}
    while true
      bytes = pipe\async_read_bytes 1024
      if #bytes > 0
        table.insert buffer, bytes.data
      else
        break

    callback table.concat buffer
  )!


loaded_frames = nil

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
    Gtk.Image {
      id: "current_image"
      file: "hi.png"
      expand: true
    }

    Gtk.HBox {
      Gtk.HScrollbar {
        id: "image_scroller"
        expand: true

        on_value_changed: =>
          value = @adjustment.value
          value = math.floor value + 0.5
          return unless loaded_frames
          frame = loaded_frames[value]
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
  }
}

window\show_all!

Gtk.main!
