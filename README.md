
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

## Installation on Ubuntu 16.04 LTS

This has been tested on a fresh install of Ubuntu 16.04 LTS.

Install git:

    $ sudo apt install git
    
Next, install all of the `gifine`'s dependencies and sub-dependencies:

    $ sudo apt install -y \
    ffmpeg \
    graphicsmagick \
	gifsicle \
	luarocks \
	libxext-dev \
	libimlib2-dev \
	mesa-utils \
	libxrender-dev \
	glew-utils \
	libglm-dev \
	cmake \
	compiz \
	gengetopt \
	libglu1-mesa-dev \
	libglew-dev \
	libxrandr-dev \
	libgirepository1.0-dev
    
Install `slop` using the instructions in the `slop` [README.md][slopread] file.

Install LGI:

	$ sudo luarocks install lgi

Install `gifine`.

	$ sudo luarocks install --server=http://luarocks.org/dev gifine

[slopread]:https://github.com/naelstrof/slop

## Demo

[![Gifine demo](https://img.youtube.com/vi/FYSoAt3EZUE/0.jpg)](https://www.youtube.com/watch?v=FYSoAt3EZUE)

## Articles

* <http://www.omgubuntu.co.uk/2016/12/gifine-animated-gif-recorder-linux>
* <https://www.gamingonlinux.com/articles/gifine-is-a-pretty-simple-open-source-tool-for-making-small-gifs-and-videos.8800>

## License

MIT, Copyright (C) 2016 by Leaf Corcoran
