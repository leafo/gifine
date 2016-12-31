
# Gifine

Gifine is a tool for recording and stitching together a short gifs or videos.
It is a GTK application implemented in MoonScript using
[lgi](https://github.com/pavouk/lgi).

You can either load a directory of frames, or select a region of your desktop
to record. After loading some frames, you can scroll through them and trim out
what isn't necessary. When you've finalized the video you can export to gif or
mp4.

It requires a few external commands to be present to function:

* [ffmpeg](https://ffmpeg.org/) — for creating mp4, and recording from desktop
* [GraphicsMagick](http://www.graphicsmagick.org/) — for creating gif
* [gifsicle](https://www.lcdf.org/gifsicle/) — for optimizing gifs
* [luarocks](https://luarocks.org) — to install the thing

In order to select a record area you need one of the following:

* [slop](https://github.com/naelstrof/slop) — Recommended
* [xrectsel](https://github.com/lolilolicon/xrectsel)

Most of these things should be able to be installed from your package manager

The recorded frames recorded aren't automatically cleaned up. You can find them
in your `/tmp` dir if you want to reload a session. Use the *load directory*
button on the initial screen.

## Install

    luarocks install --server=http://luarocks.org/dev gifine

Run the command `gifine` to use.

## Demo

[![Gifine demo](https://img.youtube.com/vi/FYSoAt3EZUE/0.jpg)](https://www.youtube.com/watch?v=FYSoAt3EZUE)

## License

MIT, Copyright (C) 2016 by Leaf Corcoran
