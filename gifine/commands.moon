import Gio, GLib from require "lgi"

random_name = ->
  chars = for i=1,10
    GLib.random_int_range "az"\byte 1,2

  "gifine_#{string.char unpack chars}"

command = (argv) ->
  process = Gio.Subprocess {
    :argv
    flags: {"INHERIT_FDS"}
  }

  process\async_wait!

command_read = (argv) ->
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

  table.concat buffer


snap_frames_rect = (callback) ->
  out = command_read { "xrectsel" }

  w, h, x, y = unpack [tonumber i for i in out\gmatch "%d+"]

  return unless w and h and x and y
  print "x: #{x}, #{y}, w: #{w}, h: #{h}"
  return if w == 0 or h == 0

  dir = "#{GLib.get_tmp_dir!}/#{random_name!}"
  print "Working in dir", dir
  command { "mkdir", dir }

  ffmpeg_process  = Gio.Subprocess {
    argv: {
      "/bin/bash"
      "-c"
      "cd #{dir} && ffmpeg -f x11grab -r 30 -s '#{w}x#{h}' -i ':0.0+#{x},#{y}' %09d.png"
    }
    flags: {"INHERIT_FDS"}
  }

  callback ffmpeg_process
  ffmpeg_process\async_wait!

  dir

-- execute command async, read entire output
async_command = (argv, callback) ->
  Gio.Async.start(-> callback command_read argv)!

{:async_command, :snap_frames_rect}
