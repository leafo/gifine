import Gio, GLib from require "lgi"

unpack = table.unpack or unpack

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

detect_command = (command) ->
  "" != command_read { "which", command }

snap_frames_rect = (framerate, callback) ->
  local x,y,w,h

  if detect_command "slop"
    out = command_read {
      "slop"
      "--nodecorations"
      "-b", "4"
      "-c", "0.3,0.3,0.8,1"
      "-f", "%x %y %w %h %c"
    }

    x, y, w, h, cancel = out\match "(%d+) (%d+) (%d+) (%d+) (%S+)"

    x = tonumber x
    y = tonumber y
    w = tonumber w
    h = tonumber h

    if cancel == "true"
      x = 0
      y = 0
      w = 0
      h = 0

  else if detect_command "xrectsel"
    out = command_read { "xrectsel" }

    w, h, x, y = unpack [tonumber i for i in out\gmatch "%d+"]

    return unless w and h and x and y
  else
    return nil, "missing command"

  return nil, "canceled selection" if w == 0 or h == 0 or x == nil

  print "Recording with x: #{x}, #{y}, w: #{w}, h: #{h}"

  dir = "#{GLib.get_tmp_dir!}/#{random_name!}"
  print "Working in dir", dir
  command { "mkdir", dir }

  display = os.getenv "DISPLAY"

  if not display or display == ""
    display = ":0"

  ffmpeg_process = Gio.Subprocess {
    argv: {
      "/bin/bash"
      "-c"
      "cd #{dir} && ffmpeg -f x11grab -r '#{framerate}' -s '#{w}x#{h}' -i '#{display}+#{x},#{y}' %09d.png"
    }
    flags: {"STDIN_PIPE"}
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

-- Send all frames to the process stdin pipe, repeating loop times
-- frames: is an array of file paths
pipe_frames = (process, frames, loop=1) ->
  pipe = process\get_stdin_pipe!

  for i=1,loop
    for frame in *frames
      print "Reading", frame
      file = Gio.File.new_for_path frame

      stream = assert file\async_read()
      while true
        bytes = assert stream\async_read_bytes 1024 * 10

        break unless bytes and #bytes > 0

        while true
          wrote = pipe\async_write_bytes bytes
          break if wrote == #bytes
          bytes = bytes\new_from_bytes wrote, #bytes - wrote


  pipe\async_close!
  process\async_wait_check!

make_webp = (frames, opts={}) ->
  framerate = opts.framerate or 60
  -- loop = opts.loop or 1
  out_name = opts.fname or "#{GLib.get_tmp_dir!}/#{random_name!}.webp"
  progress_fn = opts.progress_fn or ->

  process = Gio.Subprocess {
    argv: {
      "ffmpeg"
      "-y"
      "-f", "image2pipe"
      "-vcodec", "png"
      "-i", "-"

      "-r", "#{framerate}"
      "-c:v", "libwebp"
      "-loop", "0"
      out_name
    }
    flags: {"STDIN_PIPE"}
  }

  progress_fn "piping"
  pipe_frames process, frames

  size = file_size out_name
  out_name, size

make_mp4 = (frames, opts={}) ->
  framerate = opts.framerate or 60
  loop = opts.loop or 1
  out_name = opts.fname or "#{GLib.get_tmp_dir!}/#{random_name!}.mp4"
  progress_fn = opts.progress_fn or ->

  process = Gio.Subprocess {
    argv: {
      "ffmpeg"
      "-y"
      "-f", "image2pipe"
      "-r", "#{framerate}"
      "-vcodec", "png"
      "-i", "-"

      "-vcodec", "h264"
      "-vf", "crop=trunc(in_w/2)*2:trunc(in_h/2)*2"
      "-pix_fmt", "yuvj420p"
      "-crf", "18"
      out_name
    }
    flags: {"STDIN_PIPE"}
  }

  progress_fn "piping"
  pipe_frames process, frames, loop

  size = file_size out_name
  out_name, size

-- execute command async, read entire output
async_command = (argv, callback) ->
  Gio.Async.start(-> callback command_read argv)!

{:async_command, :snap_frames_rect, :make_gif, :make_mp4, :make_webp}
