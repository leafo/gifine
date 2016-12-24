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

file_size = (fname) ->
  res = command_read {
    "du", "-b", "-h", fname
  }

  size = res\match "^[^%s]+"
  size

snap_frames_rect = (framerate, callback) ->
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
      "cd #{dir} && ffmpeg -f x11grab -r '#{framerate}' -s '#{w}x#{h}' -i ':0.0+#{x},#{y}' %09d.png"
    }
    flags: {"INHERIT_FDS"}
  }

  callback ffmpeg_process
  ffmpeg_process\async_wait!

  dir

make_gif = (frames, opts={}) ->
  delay = opts.delay or 2
  temp_name = "#{GLib.get_tmp_dir!}/#{random_name!}.gif"
  out_name = opts.fname or "#{GLib.get_tmp_dir!}/#{random_name!}.gif"
  progress_fn = opts.progress_fn or ->

  args = {
    "gm"
    "convert"
    "-monitor"
    "-delay", tostring delay
    "-loop", "0"
  }

  for frame in *frames
    table.insert args, frame

  table.insert args, temp_name

  print "Converting to gif"
  progress_fn "converting"
  command args

  print "Optimizing gif"
  progress_fn "optimizing"
  command {
    "gifsicle"
    "--colors", "254"
    "-O2"
    temp_name
    "-o", out_name
  }

  command {
    "rm", temp_name
  }

  size = file_size out_name
  out_name, size

make_mp4 = (frames, opts={}) ->
  framerate = opts.framerate or 60
  out_name = opts.fname or "#{GLib.get_tmp_dir!}/#{random_name!}.mp4"
  progress_fn = opts.progress_fn or ->

  process  = Gio.Subprocess {
    argv: {
      "ffmpeg"
      "-y"
      "-f", "image2pipe"
      "-r", "#{framerate}"
      "-vcodec", "png"
      -- "-vcodec", "h264"
      "-vf", "'scale=trunc(in_w/2)*2:trunc(in_h/2)*2'"
      "-pix_fmt", "yuv420p"
      "-i", "-"
      out_name
    }
    flags: {"STDIN_PIPE"}
  }

  progress_fn "piping"
  pipe = process\get_stdin_pipe!

  for frame in *frames
    frame_file = io.open(frame)
    continue unless frame_file

    print "writing", frame
    contents = frame_file\read "*a"
    remaining = #contents

    while remaining > 0
      wrote = pipe\async_write contents\sub #contents - remaining + 1
      print "wrote #{wrote}"
      remaining -= wrote

  print "closing pipe"
  pipe\async_close!
  process\async_wait_check!
  size = file_size out_name
  out_name, size

-- execute command async, read entire output
async_command = (argv, callback) ->
  Gio.Async.start(-> callback command_read argv)!

{:async_command, :snap_frames_rect, :make_gif, :make_mp4}
