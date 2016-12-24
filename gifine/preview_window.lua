local Gtk
Gtk = require("lgi").Gtk
local async_command
async_command = require("gifine.commands").async_command
local PreviewWindow
do
  local _class_0
  local _base_0 = {
    loaded_frames = nil,
    working_frames = nil,
    reset_frames = function(self)
      if not (self.loaded_frames) then
        return 
      end
      do
        local _accum_0 = { }
        local _len_0 = 1
        local _list_0 = self.loaded_frames
        for _index_0 = 1, #_list_0 do
          local f = _list_0[_index_0]
          _accum_0[_len_0] = f
          _len_0 = _len_0 + 1
        end
        self.current_frames = _accum_0
      end
      local adjustment = self.window.child.image_scroller.adjustment
      local current_frame = adjustment.value
      adjustment.lower = 1
      adjustment.upper = #self.current_frames + 1
      adjustment.value = 1
    end,
    set_status = function(self, msg)
      local statusbar = self.window.child.statusbar
      local ctx = statusbar:get_context_id("default")
      return statusbar:push(ctx, msg)
    end,
    set_frames_from_dir = function(self, dir)
      return async_command({
        "find",
        dir,
        "-maxdepth",
        "1"
      }, function(res)
        local fnames
        do
          local _accum_0 = { }
          local _len_0 = 1
          for fname in res:gmatch("([^\n]+)") do
            local _continue_0 = false
            repeat
              if not (fname:match("%.png$")) then
                _continue_0 = true
                break
              end
              local _value_0 = fname
              _accum_0[_len_0] = _value_0
              _len_0 = _len_0 + 1
              _continue_0 = true
            until true
            if not _continue_0 then
              break
            end
          end
          fnames = _accum_0
        end
        table.sort(fnames)
        self.loaded_frames = fnames
        self:reset_frames()
        return self:set_status("Loaded " .. tostring(dir))
      end)
    end,
    create = function(self)
      self.window = Gtk.Window({
        title = "Preview",
        default_width = 256,
        default_height = 256,
        on_destroy = function()
          return Gtk.main_quit()
        end,
        on_key_press_event = function(win, e)
          if e.string:byte() == 27 then
            return Gtk.main_quit()
          end
        end,
        Gtk.VBox({
          Gtk.VBox({
            spacing = 4,
            border_width = 8,
            Gtk.Image({
              id = "current_image",
              expand = true
            }),
            self:create_scrubber(),
            self:create_gif_export(),
            self:create_video_export()
          }),
          Gtk.Statusbar({
            id = "statusbar"
          })
        })
      })
    end,
    create_video_export = function(self)
      return Gtk.Frame({
        label = "Encode video",
        Gtk.HBox({
          spacing = 4,
          border_width = 8,
          Gtk.Button({
            label = "Save MP4...",
            on_clicked = function(btn)
              local Gio
              Gio = require("lgi").Gio
              local make_mp4
              make_mp4 = require("gifine.commands").make_mp4
              local save_to = self:choose_save_file()
              if not (save_to) then
                return 
              end
              btn.sensitive = false
              local framerate = self.window.child.framerate_input.adjustment.value
              return Gio.Async.start(function()
                local out_fname = make_mp4(self.current_frames, {
                  fname = save_to,
                  framerate = framerate,
                  progress_fn = function(step)
                    return self:set_status("Working: " .. tostring(step))
                  end
                })
                self:set_status("Wrote mp4 to " .. tostring(out_fname))
                btn.sensitive = true
              end)()
            end
          }),
          Gtk.VBox({
            spacing = 2,
            Gtk.SpinButton({
              id = "framerate_input",
              expand = true,
              adjustment = Gtk.Adjustment({
                lower = 10,
                upper = 120,
                value = 60,
                page_size = 1,
                step_increment = 1
              })
            }),
            Gtk.Label({
              label = "Framerate"
            })
          })
        })
      })
    end,
    create_gif_export = function(self)
      return Gtk.Frame({
        label = "Encode GIF",
        Gtk.HBox({
          spacing = 4,
          border_width = 8,
          Gtk.Button({
            label = "Save GIF...",
            on_clicked = function(btn)
              local Gio
              Gio = require("lgi").Gio
              local make_gif
              make_gif = require("gifine.commands").make_gif
              local save_to = self:choose_save_file()
              if not (save_to) then
                return 
              end
              btn.sensitive = false
              local delay = self.window.child.delay_input.adjustment.value
              return Gio.Async.start(function()
                local out_fname = make_gif(self.current_frames, {
                  fname = save_to,
                  delay = delay,
                  progress_fn = function(step)
                    return self:set_status("Working: " .. tostring(step))
                  end
                })
                self:set_status("Wrote gif to " .. tostring(out_fname))
                btn.sensitive = true
              end)()
            end
          }),
          Gtk.VBox({
            spacing = 2,
            Gtk.SpinButton({
              id = "delay_input",
              expand = true,
              adjustment = Gtk.Adjustment({
                lower = 1,
                upper = 10,
                value = 2,
                page_size = 1,
                step_increment = 1
              })
            }),
            Gtk.Label({
              label = "Delay"
            })
          })
        })
      })
    end,
    create_scrubber = function(self)
      return Gtk.HBox({
        spacing = 4,
        Gtk.Button({
          label = "Trim left of"
        }),
        Gtk.HScale({
          id = "image_scroller",
          expand = true,
          round_digits = 0,
          digits = 0,
          on_value_changed = function(scroller)
            local value = scroller.adjustment.value
            value = math.floor(value + 0.5)
            if not (self.current_frames) then
              return 
            end
            self.current_frame_idx = value
            local frame = self.current_frames[value]
            self.window.child.current_image.file = frame
          end,
          adjustment = Gtk.Adjustment({
            lower = 0,
            upper = 100,
            value = 50,
            page_size = 1,
            step_increment = 1
          })
        }),
        Gtk.Button({
          label = "Trim right of"
        }),
        Gtk.Button({
          label = "Delete frame"
        })
      })
    end,
    choose_save_file = function(self)
      local save_to
      local dialog = Gtk.FileChooserDialog({
        title = "Save to GIF",
        action = Gtk.FileChooserAction.SAVE,
        transient_for = self.window,
        buttons = {
          {
            Gtk.STOCK_SAVE,
            Gtk.ResponseType.ACCEPT
          },
          {
            Gtk.STOCK_CLOSE,
            Gtk.ResponseType.CANCEL
          }
        },
        on_response = function(dialog, response)
          local _exp_0 = response
          if Gtk.ResponseType.ACCEPT == _exp_0 then
            save_to = dialog:get_filename()
          elseif Gtk.ResponseType.CANCEL == _exp_0 then
            return nil
          end
        end
      })
      dialog:run()
      dialog:destroy()
      return save_to
    end
  }
  _base_0.__index = _base_0
  _class_0 = setmetatable({
    __init = function(self)
      self:create()
      self.window:show_all()
      return self:set_status("Ready")
    end,
    __base = _base_0,
    __name = "PreviewWindow"
  }, {
    __index = _base_0,
    __call = function(cls, ...)
      local _self_0 = setmetatable({}, _base_0)
      cls.__init(_self_0, ...)
      return _self_0
    end
  })
  _base_0.__class = _class_0
  PreviewWindow = _class_0
end
return {
  PreviewWindow = PreviewWindow
}
