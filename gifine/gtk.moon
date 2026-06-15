lgi = require "lgi"

-- Workaround for lgi vs glib >= 2.88: the GEnumClass `values` array field is
-- now marshaled as a Lua table (1-based) instead of a record pointer, so the
-- stock ffi.load_enum passes a table to core.record.fromarray and crashes with
-- "bad argument #1 to 'fromarray' (lgi.record expected, got table)". Patch
-- load_enum before Gtk (which pulls in the cairo override) is loaded.
do
  ffi = require "lgi.ffi"
  core = require "lgi.core"
  component = require "lgi.component"
  enum = require "lgi.enum"

  ffi.load_enum = (gtype, name) ->
    GObject = core.repo.GObject
    is_flags = GObject.Type.is_a gtype, GObject.Type.FLAGS
    enum_component = component.create gtype, (is_flags and enum.bitflags_mt or enum.enum_mt), name
    type_class = GObject.TypeClass.ref gtype
    enum_class = core.record.cast type_class, (is_flags and GObject.FlagsClass or GObject.EnumClass)
    values = enum_class.values
    for i = 0, enum_class.n_values - 1
      val = if type(values) == "table"
        values[i + 1]
      else
        core.record.fromarray values, i
      enum_component[core.upcase(val.value_nick)\gsub("%-", "_")] = val.value
    type_class\unref!
    enum_component

Gtk = lgi.require("Gtk", "3.0")

{:Gtk}
