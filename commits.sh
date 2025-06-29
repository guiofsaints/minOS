#!/bin/bash

show() {
	pushd "$1" >> /dev/null
	HASH=$(git rev-parse --short=8 HEAD)
	NAME=$(basename $PWD)
	DATE=$(git log -1 --pretty='%ad' --date=format:'%Y-%m-%d')
	REPO=$(git config --get remote.origin.url)
	REPO=$(sed -E "s,(^git@github.com:)|(^https?://github.com/)|(.git$)|(/$),,g" <<<"$REPO")
	popd >> /dev/null

	printf '\055 %-24s%-10s%-12s%s\n' $NAME $HASH $DATE $REPO
}
list() {
	pushd "$1" >> /dev/null
	for D in ./*; do
		show "$D"
	done
	popd >> /dev/null
}
rule() {
	echo '----------------------------------------------------------------'	
}
tell() {
	echo $1
	rule
}

cores() {
	echo CORES
	list ./workspace/$1/cores/src
	bump
}

bump() {
	printf '\n'
}

{
	# tell minOS
	printf '%-26s%-10s%-12s%s\n' MINOS HASH DATE USER/REPO
	rule
	show ./
	bump
	
	tell TOOLCHAINS
	list ./toolchains
	bump
	
	tell LIBRETRO
	show ./workspace/all/minarch/libretro-common
	bump
	
	tell TG5040
	show ./workspace/tg5040/other/evtest
	show ./workspace/tg5040/other/jstest
	show ./workspace/tg5040/other/unzip60
	cores tg5040

} 2>&1
	
	tell ZERO28
	show ./workspace/zero28/other/DinguxCommander-sdl2
	cores tg5040 # just copied from tg5040
	
	tell MY355
	show ./workspace/my355/other/evtest
	show ./workspace/my355/other/mkbootimg
	show ./workspace/my355/other/rsce-go
	show ./workspace/my355/other/DinguxCommander-sdl2
	cores my355
	
	tell CHECK
	echo https://github.com/USER/REPO/compare/HASH...HEAD
	bump
} | sed 's/\n/ /g'