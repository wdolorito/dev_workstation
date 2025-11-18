#!/bin/sh

#
# ~/.local/suckless/compile_suckless.sh
#

export CC=clang
export LDFLAGS=-fuse-ld=lld
BUILDDIR="$HOME"/.local/suckless/src
TOPLEVEL="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit 1; pwd -P)"
if ! [ -d "$BUILDDIR" ]
then
  mkdir -p "$BUILDDIR"
fi

# clone and build suckless tools

clone_and_build() {
  cd "$BUILDDIR" || exit
  if ! [ -d "$DIR" ]
  then
    git clone "$URL" "$DIR"
  fi
  rm -f "$BUILDDIR/$DIR/config.h"
  rm -f "$BUILDDIR/$DIR/config.mk"
  cd "$DIR" || exit
  if [ -n "$PATCH" ]
  then
    for patch in $PATCH
    do
      curl "$patch" -O
      patch -Np1 -i "$(basename "${patch}")"
    done
  fi
  cp -v "$TOPLEVEL/suckless-conf/$CONFIG" "$BUILDDIR/$DIR/config.h"
  cp -v "$TOPLEVEL/suckless-conf/$MKCONFIG" "$BUILDDIR/$DIR/config.mk"
  make clean install
}

reset_vars() {
  DIR=""
  CONFIG=""
  MKCONFIG=""
  URL=""
  PATCH=""
}

do_dwm() {
  DIR="dwm"
  CONFIG="dwm-config.h"
  MKCONFIG="dwm-config.mk"
  URL="https://git.suckless.org/dwm"
  PATCH="https://dwm.suckless.org/patches/fullgaps/dwm-fullgaps-6.4.diff https://dwm.suckless.org/patches/hide_vacant_tags/dwm-hide_vacant_tags-6.4.diff"
  clone_and_build
  reset_vars
}

do_dmenu() {
  DIR="dmenu"
  CONFIG="dmenu-config.h"
  MKCONFIG="dmenu-config.mk"
  URL="https://git.suckless.org/dmenu"
  clone_and_build
  reset_vars
}

do_slstatus() {
  DIR="slstatus"
  CONFIG="slstatus-config.h"
  MKCONFIG="slstatus-config.mk"
  URL="https://git.suckless.org/slstatus"
  clone_and_build
  reset_vars
}

do_st() {
  DIR="st"
  CONFIG="st-config.h"
  MKCONFIG="st-config.mk"
  URL="https://git.suckless.org/st"
  PATCH="https://st.suckless.org/patches/scrollback/st-scrollback-0.8.5.diff"
  clone_and_build
  reset_vars
}

do_all() {
  do_dwm
  do_dmenu
  do_slstatus
  do_st
}


case "$1" in
	"dwm" )
		do_dwm
		;;
	"dmenu" )
		do_dmenu
		;;
	"slstatus" )
		do_slstatus
		;;
	"st" )
		do_st
		;;
	* )
		rm -rf "$BUILDDIR"
		do_all
		;;
esac
