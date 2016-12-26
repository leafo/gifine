local Gio, GLib
do
  local _obj_0 = require("lgi")
  Gio, GLib = _obj_0.Gio, _obj_0.GLib
end
local random_name
random_name = function()
  local chars
  do
    local _accum_0 = { }
    local _len_0 = 1
    for i = 1, 10 do
      _accum_0[_len_0] = GLib.random_int_range(("az"):byte(1, 2))
      _len_0 = _len_0 + 1
    end
    chars = _accum_0
  end
  return "gifine_" .. tostring(string.char(unpack(chars)))
end
local command
command = function(argv)
  local process = Gio.Subprocess({
    argv = argv,
    flags = {
      "INHERIT_FDS"
    }
  })
  return process:async_wait()
end
local command_read
command_read = function(argv)
  local process = Gio.Subprocess({
    argv = argv,
    flags = {
      "STDOUT_PIPE"
    }
  })
  local pipe = process:get_stdout_pipe()
  local buffer = { }
  while true do
    local bytes = pipe:async_read_bytes(1024)
    if #bytes > 0 then
      table.insert(buffer, bytes.data)
    else
      break
    end
  end
  return table.concat(buffer)
end
local file_size
file_size = function(fname)
  local res = command_read({
    "du",
    "-b",
    "-h",
    fname
  })
  local size = res:match("^[^%s]+")
  return size
end
local snap_frames_rect
snap_frames_rect = function(framerate, callback)
  local out = command_read({
    "xrectsel"
  })
  local w, h, x, y = unpack((function()
    local _accum_0 = { }
    local _len_0 = 1
    for i in out:gmatch("%d+") do
      _accum_0[_len_0] = tonumber(i)
      _len_0 = _len_0 + 1
    end
    return _accum_0
  end)())
  if not (w and h and x and y) then
    return 
  end
  print("x: " .. tostring(x) .. ", " .. tostring(y) .. ", w: " .. tostring(w) .. ", h: " .. tostring(h))
  if w == 0 or h == 0 then
    return 
  end
  local dir = tostring(GLib.get_tmp_dir()) .. "/" .. tostring(random_name())
  print("Working in dir", dir)
  command({
    "mkdir",
    dir
  })
  local ffmpeg_process = Gio.Subprocess({
    argv = {
      "/bin/bash",
      "-c",
      "cd " .. tostring(dir) .. " && ffmpeg -f x11grab -r '" .. tostring(framerate) .. "' -s '" .. tostring(w) .. "x" .. tostring(h) .. "' -i ':0.0+" .. tostring(x) .. "," .. tostring(y) .. "' %09d.png"
    },
    flags = {
      "INHERIT_FDS"
    }
  })
  callback(ffmpeg_process)
  ffmpeg_process:async_wait()
  return dir
end
local make_gif
make_gif = function(frames, opts)
  if opts == nil then
    opts = { }
  end
  local delay = opts.delay or 2
  local temp_name = tostring(GLib.get_tmp_dir()) .. "/" .. tostring(random_name()) .. ".gif"
  local out_name = opts.fname or tostring(GLib.get_tmp_dir()) .. "/" .. tostring(random_name()) .. ".gif"
  local progress_fn = opts.progress_fn or function() end
  local args = {
    "gm",
    "convert",
    "-monitor",
    "-delay",
    tostring(delay),
    "-loop",
    "0"
  }
  for _index_0 = 1, #frames do
    local frame = frames[_index_0]
    table.insert(args, frame)
  end
  table.insert(args, temp_name)
  print("Converting to gif")
  progress_fn("converting")
  command(args)
  print("Optimizing gif")
  progress_fn("optimizing")
  command({
    "gifsicle",
    "--colors",
    "254",
    "-O2",
    temp_name,
    "-o",
    out_name
  })
  command({
    "rm",
    temp_name
  })
  local size = file_size(out_name)
  return out_name, size
end
local make_mp4
make_mp4 = function(frames, opts)
  if opts == nil then
    opts = { }
  end
  local framerate = opts.framerate or 60
  local loop = opts.loop or 1
  local out_name = opts.fname or tostring(GLib.get_tmp_dir()) .. "/" .. tostring(random_name()) .. ".mp4"
  local progress_fn = opts.progress_fn or function() end
  local process = Gio.Subprocess({
    argv = {
      "ffmpeg",
      "-y",
      "-f",
      "image2pipe",
      "-r",
      tostring(framerate),
      "-vcodec",
      "png",
      "-i",
      "-",
      "-vcodec",
      "h264",
      "-vf",
      "scale=trunc(in_w/2)*2:trunc(in_h/2)*2",
      "-pix_fmt",
      "yuv420p",
      out_name
    },
    flags = {
      "STDIN_PIPE"
    }
  })
  progress_fn("piping")
  local pipe = process:get_stdin_pipe()
  for i = 1, loop do
    for _index_0 = 1, #frames do
      local frame = frames[_index_0]
      print("Reading", frame)
      local file = Gio.File.new_for_path(frame)
      local stream = assert(file:async_read())
      while true do
        local bytes = assert(stream:async_read_bytes(1024 * 10))
        if not (bytes and #bytes > 0) then
          break
        end
        while true do
          local wrote = pipe:async_write_bytes(bytes)
          if wrote == #bytes then
            break
          end
          bytes = bytes:new_from_bytes(wrote, #bytes - wrote)
        end
      end
    end
  end
  print("closing pipe")
  pipe:async_close()
  process:async_wait_check()
  local size = file_size(out_name)
  return out_name, size
end
local async_command
async_command = function(argv, callback)
  return Gio.Async.start(function()
    return callback(command_read(argv))
  end)()
end
return {
  async_command = async_command,
  snap_frames_rect = snap_frames_rect,
  make_gif = make_gif,
  make_mp4 = make_mp4
}
