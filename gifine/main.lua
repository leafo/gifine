local Gtk
Gtk = require("lgi").Gtk
local LoadWindow
LoadWindow = require("gifine.load_window").LoadWindow
LoadWindow()
return Gtk.main()
