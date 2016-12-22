

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

image = Gtk.Image {
  file: "hi.png"
  expand: true
}

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
    image

    Gtk.Scrollbar { }

    Gtk.Button {
      label: "Load images"

      on_clicked: =>
        async_command {"find", "frames/"}, (res) ->
          print "get res", res

        print ">> button is clicked"
    }
  }
}

window\show_all!

Gtk.main!
