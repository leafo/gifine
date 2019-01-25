local Gtk
Gtk = require("lgi").Gtk
do
  local path = arg and unpack(arg)
  if path then
    local PreviewWindow
    PreviewWindow = require("gifine.preview_window").PreviewWindow
    local preview = PreviewWindow()
    preview:set_frames_from_dir(path)
  else
    local LoadWindow
    LoadWindow = require("gifine.load_window").LoadWindow
    LoadWindow()
  end
end
return Gtk.main()
