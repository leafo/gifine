.PHONY: compile debug

compile: bin/gifine
	moonc gifine

local: compile
	luarocks make --local gifine-dev-1.rockspec

debug:
	GTK_DEBUG=interactive moon bin/gifine.moon

bin/gifine: bin/gifine.moon
	echo "#!/usr/bin/env lua" > bin/gifine
	moonc -p bin/gifine.moon >> bin/gifine
	echo "-- vim: set filetype=lua:" >> bin/gifine
	chmod +x bin/gifine
