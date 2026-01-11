#!/bin/sh

#
# ~/.local/suckless/compile_suckless.sh
#
BUILDDIR="$HOME"/.local/suckless/src
TOPLEVEL="$(cd -- "$(dirname "$0")" >/dev/null 2>&1 || exit 1; pwd -P)"

check_builddir() {
  if ! [ -d "$BUILDDIR" ]
  then
    mkdir -p "$BUILDDIR"
  fi
}

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

do_xob() {
  export CC=clang
  export LDFLAGS=-fuse-ld=lld
  cd "$BUILDDIR" || exit
  if ! [ -d "xob" ]
  then
    git clone "https://github.com/florentc/xob.git"
  else
    rm -rf xob
    git clone "https://github.com/florentc/xob.git"
  fi
  cd xob || exit
  CC=clang LDFLAGS=-fuse-ld=lld prefix="$HOME/.local" make install
  if [ -d "$HOME/.local/etc" ]
  then
    rm -rf "$HOME/.local/etc"
  fi
  if ! [ -d "$HOME/.config/xob" ]
  then
    mkdir -p "$HOME/.config/xob"
  fi
  cp -v "$TOPLEVEL/suckless-conf/styles.cfg" "$HOME/.config/xob"
}

do_all() {
  check_builddir
  do_dwm
  do_dmenu
  do_slstatus
  do_st
  do_xob
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
	"xob" )
		do_xob
		;;
	* )
		rm -rf "$BUILDDIR"
		do_all
		;;
esac
