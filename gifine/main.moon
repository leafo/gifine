
import Gtk from require "gifine.gtk"

if path = arg and unpack arg
  import PreviewWindow from require "gifine.preview_window"
  preview = PreviewWindow!
  preview\set_frames_from_dir path
else
  import LoadWindow from require "gifine.load_window"
  LoadWindow!


Gtk.main!
