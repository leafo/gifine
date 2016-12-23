package = "gifine"
version = "dev-1"

source = {
  url = "git://github.com/leafo/gifine.git"
}

description = {
  summary = "A tool for make gifs and videos",
  homepage = "https://github.com/leafo/gifine",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
  "lgi"
}

build = {
  type = "builtin",
  modules = {
    ["gifine.commands"] = "gifine/commands.lua",
    ["gifine.load_window"] = "gifine/load_window.lua",
    ["gifine.main"] = "gifine/main.lua",
    ["gifine.preview_window"] = "gifine/preview_window.lua",
  },
  install = {
    bin = { "bin/gifine" }
  }
}

