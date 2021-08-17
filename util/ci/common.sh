#!/bin/bash -e

# Linux build only
install_linux_deps() {
	local pkgs=(cmake libpng-dev \
		libjpeg-dev libxxf86vm-dev libgl1-mesa-dev libsqlite3-dev \
		libhiredis-dev libogg-dev libgmp-dev libvorbis-dev libopenal-dev \
		gettext libpq-dev libleveldb-dev libcurl4-openssl-dev)

	if [[ "$1" == "--old-irr" ]]; then
		shift
		pkgs+=(libirrlicht-dev)
	else
		# TODO: return old URL when IrrlichtMt 1.9.0mt2 is tagged
		#wget "https://github.com/minetest/irrlicht/releases/download/1.9.0mt1/ubuntu-bionic.tar.gz"
		wget "http://minetest.kitsunemimi.pw/irrlichtmt-patched-temporary.tgz" -O ubuntu-bionic.tar.gz
		sudo tar -xaf ubuntu-bionic.tar.gz -C /usr/local
	fi

	sudo apt-get update
	sudo apt-get install -y --no-install-recommends ${pkgs[@]} "$@"
}

# Mac OSX build only
install_macosx_deps() {
	brew update
	brew install freetype gettext hiredis irrlicht leveldb libogg libvorbis luajit
	if brew ls | grep -q jpeg; then
		brew upgrade jpeg
	else
		brew install jpeg
	fi
	#brew upgrade postgresql
}
