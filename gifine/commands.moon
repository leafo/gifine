import Gio from require "lgi"

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


snap_frames_rect = ->
  print "starting command........"
  out = command_read { "xrectsel" }

  w, h, x, y = unpack [tonumber i for i in out\gmatch "%d+"]

  return unless w and h and x and y
  print "x: #{x}, #{y}, w: #{w}, h: #{h}"
  return if w == 0 or h == 0


-- execute command async, read entire output
async_command = (argv, callback) ->
  Gio.Async.start(-> callback command_read argv)!

{:async_command, :snap_frames_rect}
