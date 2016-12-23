.PHONY: compile

local: compile
	luarocks make --local gifine-dev-1.rockspec

compile: bin/gifine
	moonc gifine

bin/gifine: bin/gifine.moon
	echo "#!/usr/bin/env lua" > bin/gifine
	moonc -p bin/gifine.moon >> bin/gifine
	echo "-- vim: set filetype=lua:" >> bin/gifine
	chmod +x bin/gifine
