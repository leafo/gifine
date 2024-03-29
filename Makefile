.PHONY: compile debug lint run

run: compile
	moon bin/gifine.moon

compile: bin/gifine
	moonc gifine

lint:
	moonc -l gifine

local: compile
	luarocks --lua-version=5.1 make --local gifine-dev-1.rockspec

debug:
	GTK_DEBUG=interactive moon bin/gifine.moon

bin/gifine: bin/gifine.moon
	echo "#!/usr/bin/env lua" > bin/gifine
	moonc -p bin/gifine.moon >> bin/gifine
	echo "-- vim: set filetype=lua:" >> bin/gifine
	chmod +x bin/gifine
