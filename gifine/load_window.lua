local Gtk
Gtk = require("lgi").Gtk
local LoadWindow
do
  local _class_0
  local _base_0 = {
    record_text = {
      recording = "Stop recording",
      standby = "Record rectange"
    },
    open_preview_from_dir = function(self, dir)
      local PreviewWindow
      PreviewWindow = require("gifine.preview_window").PreviewWindow
      self.window:hide()
      local preview = PreviewWindow()
      return preview:set_frames_from_dir(dir)
    end,
    create = function(self)
      self.window = Gtk.Window({
        title = "Record or load frames",
        border_width = 8,
        default_width = 300,
        default_height = 128,
        on_destroy = function()
          return Gtk.main_quit()
        end,
        on_key_press_event = function(win, e)
          if e.string:byte() == 27 then
            return Gtk.main_quit()
          end
        end,
        Gtk.VBox({
          spacing = 8,
          Gtk.Frame({
            Gtk.HBox({
              border_width = 8,
              spacing = 4,
              self:create_record_button(),
              Gtk.VBox({
                spacing = 2,
                Gtk.SpinButton({
                  id = "framerate_input",
                  expand = true,
                  adjustment = Gtk.Adjustment({
                    lower = 1,
                    upper = 80,
                    value = 30,
                    page_size = 1,
                    step_increment = 1
                  })
                }),
                Gtk.Label({
                  label = "Framerate"
                })
              })
            })
          }),
          Gtk.Frame({
            Gtk.VBox({
              spacing = 4,
              border_width = 8,
              Gtk.Label({
                label = "Load directory of frames"
              }),
              Gtk.FileChooserButton({
                title = "Pick a Folder",
                action = "SELECT_FOLDER",
                on_file_set = function(picker)
                  local folder = picker:get_filename()
                  if not (folder) then
                    return 
                  end
                  return self:open_preview_from_dir(folder)
                end
              })
            })
          })
        })
      })
    end,
    create_record_button = function(self)
      return Gtk.Button({
        id = "record_button",
        label = self.record_text.standby,
        on_clicked = function()
          if self.ffmpeg_process then
            self.ffmpeg_process:force_exit()
            return 
          end
          local framerate = self.window.child.framerate_input.adjustment.value
          framerate = framerate or 30
          local Gio
          Gio = require("lgi").Gio
          local snap_frames_rect
          snap_frames_rect = require("gifine.commands").snap_frames_rect
          return Gio.Async.start(function()
            local dir, err = snap_frames_rect(framerate, function(ffmpeg_process)
              self.ffmpeg_process = ffmpeg_process
              self.window.child.record_button.label = self.record_text.recording
            end)
            if not (dir) then
              if err == "missing command" then
                self:show_alert("Missing command", "You need either slop or xrectsel installed to select a rectangle to record. Check README.md for more information.")
              end
              return 
            end
            self.ffmpeg_process = nil
            self.window.child.record_button.label = self.record_text.standby
            return self:open_preview_from_dir(dir)
          end)()
        end
      })
    end,
    show_alert = function(self, title, text)
      local dialog = Gtk.MessageDialog({
        text = title,
        secondary_text = text,
        message_type = Gtk.MessageType.ERROR,
        buttons = Gtk.ButtonsType.CLOSE,
        transient_for = self.window
      })
      dialog:run()
      return dialog:destroy()
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self:create()
      return self.window:show_all()
    end,
    __base = _base_0,
    __name = "LoadWindow"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  LoadWindow = _class_0
end
return {
  LoadWindow = LoadWindow
}
