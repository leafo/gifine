local lgi = require("lgi")
do
  local ffi = require("lgi.ffi")
  local core = require("lgi.core")
  local component = require("lgi.component")
  local enum = require("lgi.enum")
  ffi.load_enum = function(gtype, name)
    local GObject = core.repo.GObject
    local is_flags = GObject.Type.is_a(gtype, GObject.Type.FLAGS)
    local enum_component = component.create(gtype, (is_flags and enum.bitflags_mt or enum.enum_mt), name)
    local type_class = GObject.TypeClass.ref(gtype)
    local enum_class = core.record.cast(type_class, (is_flags and GObject.FlagsClass or GObject.EnumClass))
    local values = enum_class.values
    for i = 0, enum_class.n_values - 1 do
      local val
      if type(values) == "table" then
        val = values[i + 1]
      else
        val = core.record.fromarray(values, i)
      end
      enum_component[core.upcase(val.value_nick):gsub("%-", "_")] = val.value
    end
    type_class:unref()
    return enum_component
  end
end
local Gtk = lgi.require("Gtk", "3.0")
return {
  Gtk = Gtk
}
