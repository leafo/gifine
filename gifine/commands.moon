import Gio from require "lgi"

-- execute command async, read entire output
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

{:async_command}
