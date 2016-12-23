
# Gifine

Gifine is a tool for recording and stitching together a short gifs or videos.
It is a GTK application implemented in MoonScript using
[lgi](https://github.com/pavouk/lgi).

You can either load a directory of frames, or select a region of your desktop
to record. After loading some frames, you can scroll through them and trim out
what isn't necessary. When you've finalized the video you can export to gif or
mp4.

It requires a few external commands to be present to function:

* ffmpeg — for creating mp4, and recording from desktop
* GraphicsMagick — for creating gif
* xrectsel — for selecting a record area
* gifsicle — for optimizing gifs

## Install

    luarocks install --server=http://luarocks.org/dev gifine

Run the comman `gifine` to use.

## Screenshots

![Screenshot](http://leafo.net/shotsnb/2016-12-23_11-51-01.png)

## License

MIT, Copyright (C) 2016 by Leaf Corcoran
