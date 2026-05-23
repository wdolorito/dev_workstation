#!/bin/sh

ARCHIVES="$(pwd)/archives"
CURL="$(which curl 2>/dev/null)"
KERN="$(uname -s)"
LOWERKERN="$(echo "$KERN" | tr '[:upper:]' '[:lower:]')"
MACHRAW="$(uname -m)"
MACH="$MACHRAW"
BWD="$(pwd)"
PROGS="$BWD/dev_progs"
SRC="$BWD/src"
CLVOJDK=""
CLVNODE=""
CLVVAGRANT=""
CLVLLVM=""
CLVNINJA=""
CLVCMAKE=""
CLVPYTHON=""
TAR="$(which tar 2>/dev/null)"
ZIP="$(which 7z 2>/dev/null)"

if [ -z "$CURL" ]
then
	echo "curl command not available."
	exit 127
fi

if [ "$MACH" = "x86_64" ]
then
	MACH="x64"
fi

if ! [ -d "$ARCHIVES" ]
then
	mkdir -p "$ARCHIVES"
fi

test_progs_dir() {
	if ! [ -d "$PROGS" ]
	then
		mkdir -p "$PROGS"
	fi
}

test_src_dir() {
	if ! [ -d "$SRC" ]
	then
		mkdir -p "$SRC"
	fi
}

download_openjdk() {
	LATESTLTS="$($CURL -s 'https://api.adoptium.net/v3/info/available_releases' | grep most_recent_lts | cut -d: -f2 | tr -d ",|[:space:]")"
	LINK="$($CURL -s "https://api.adoptium.net/v3/assets/latest/$LATESTLTS/hotspot?architecture=$MACH&os=$LOWERKERN" | grep \"link | grep "jdk_$MACH" | cut -d: -f2- | tr -d ",|[:space:]|\"")"
	FILE="$(basename "$LINK")"
	CLVOJDK="$ARCHIVES/$FILE"
	if [ -f "$CLVOJDK" ]
	then
		printf "latest openjdk archive exists.\t%s\n" "$CLVOJDK"
	else
		echo "Downloading openjdk..."
		$CURL -L -o "$CLVOJDK" "$LINK"
	fi
}

unpack_openjdk() {
	if [ -n "$TAR" ]
	then
		echo "unpacking openjdk to" "$PROGS" "..."
		$TAR xf "$CLVOJDK"  --strip-components=1 -C "$PROGS"
	else
		echo "tar command not available."
		exit 127
	fi
}

download_node() {
	URL="https://nodejs.org"
	LATESTLTS="$($CURL -s "$URL/dist/" | grep "latest-v..\." | cut -d"=" -f2 | cut -d">" -f1 | tr -d \"/ | sort | tail -n3 | head -n1 )"
	ENDPOINT="$($CURL -s "$URL/dist/$LATESTLTS/" | grep node | grep xz | grep "$LOWERKERN" | grep "$MACH" | cut -d">" -f1 | cut -d= -f2 | tr -d \")"
	FILE="$(basename "$URL$ENDPOINT")"
	CLVNODE="$ARCHIVES/$FILE"
	if [ -f "$CLVNODE" ]
	then
		printf "latest nodejs archive exists.\t%s\n" "$CLVNODE"
	else
		echo "Downloading nodejs..."
		$CURL -L -o "$CLVNODE" "$URL$ENDPOINT"
	fi
}

unpack_node() {
	if [ -n "$TAR" ]
	then
		echo "unpacking node to" "$PROGS" "..."
		$TAR xf "$CLVNODE"  --strip-components=1 -C "$PROGS"
	else
		echo "tar command not available."
		exit 127
	fi
}

download_vagrant() {
	URL="https://releases.hashicorp.com"
	LATEST="$($CURL -s "$URL/vagrant/" | grep vagrant_ | head -n1 | awk -F\" '{print $2}')"
	LINK="$($CURL -s "$URL$LATEST" | grep "$LOWERKERN" | grep zip | cut -d">" -f1 | rev | cut -d= -f1 | rev | tr -d \")"
	FILE="$(basename "$LINK")"
	CLVVAGRANT="$ARCHIVES/$FILE"
	if [ -f "$CLVVAGRANT" ]
	then
		printf "latest vagrant archive exists.\t%s\n" "$CLVVAGRANT"
	else
		echo "Downloading vagrant..."
		$CURL -L -o "$CLVVAGRANT" "$LINK"
	fi
}

unpack_vagrant() {
	if [ -n "$ZIP" ]
	then
		echo "unpacking vagrant to" "$PROGS/bin" "..."
		7z x "$CLVVAGRANT"  -o"$PROGS"/bin
	else
		echo "zip command not available."
		exit 127
	fi
}

download_llvm() {
	LATEST="$($CURL -s "https://api.github.com/repos/llvm/llvm-project/releases/latest" | grep browser | grep "$KERN" | grep -i "$MACH" | grep "xz\"" | cut -d":" -f2- | tr -d "\"|[:space:]")"
	FILE="$(basename "$LATEST")"
	CLVLLVM="$ARCHIVES/$FILE"
	if [ -f "$CLVLLVM" ]
	then
		printf "latest llvm archive exists.\t%s\n" "$CLVLLVM"
	else
		echo "Downloading llvm..."
		$CURL -L -o "$CLVLLVM" "$LATEST"
	fi
}

unpack_llvm() {
	if [ -n "$TAR" ]
	then
		echo "unpacking llvm to" "$PROGS" "..."
		$TAR xf "$CLVLLVM"  --strip-components=1 -C "$PROGS"
	else
		echo "tar command not available."
		exit 127
	fi
}

download_ninja() {
	LATEST="$($CURL -s "https://api.github.com/repos/ninja-build/ninja/releases/latest" | grep browser | grep "$LOWERKERN\.zip" | cut -d":" -f2- | tr -d "\"|[:space:]")"
	FILE="$(basename "$LATEST")"
	CLVNINJA="$ARCHIVES/$FILE"
	if [ -f "$CLVNINJA" ]
	then
		printf "latest ninja archive exists.\t%s\n" "$CLVNINJA"
	else
		echo "Downloading ninja..."
		$CURL -L -o "$CLVNINJA" "$LATEST"
	fi
}

unpack_ninja() {
	if [ -n "$ZIP" ]
	then
		echo "unpacking ninja to" "$PROGS/bin" "..."
		7z x "$CLVNINJA"  -o"$PROGS"/bin
	else
		echo "zip command not available."
		exit 127
	fi
}

download_cmake() {
	LATEST="$($CURL -s "https://api.github.com/repos/Kitware/CMake/releases/latest" | grep browser | grep tar | grep "$MACHRAW" | grep "$LOWERKERN" | cut -d":" -f2- | tr -d "\"|[:space:]")"
	FILE="$(basename "$LATEST")"
	CLVCMAKE="$ARCHIVES/$FILE"
	if [ -f "$CLVCMAKE" ]
	then
		printf "latest cmake archive exists.\t%s\n" "$CLVCMAKE"
	else
		echo "Downloading cmake..."
		$CURL -L -o "$CLVCMAKE" "$LATEST"
	fi
}

unpack_cmake() {
	if [ -n "$TAR" ]
	then
		echo "unpacking cmake to" "$PROGS" "..."
		$TAR xf "$CLVCMAKE"  --strip-components=1 -C "$PROGS"
	else
		echo "tar command not available."
		exit 127
	fi
}

download_python() {
	URL="https://www.python.org/ftp/python"
	LATEST="$($CURL -s "$URL/" | grep "\"3\...\." | cut -d= -f2 | cut -d/ -f1  | cut -d\" -f2 | tail -n2 | head -n1)"
	FILE="$($CURL -s "$URL/$LATEST/" | grep xz | head -n1 | cut -d\" -f2 | tr -d "=")"
	CLVPYTHON="$ARCHIVES/$FILE"
	if [ -f "$CLVPYTHON" ]
	then
		printf "latest python archive exists.\t%s\n" "$CLVPYTHON"
	else
		echo "Downloading python..."
		$CURL -L -o "$CLVPYTHON" "$URL/$LATEST/$FILE"
	fi
}

unpack_python() {
	if [ -n "$TAR" ]
	then
		echo "unpacking python to" "$SRC" "..."
		test_src_dir
		$TAR xf "$CLVPYTHON"  -C "$SRC"
	else
		echo "tar command not available."
		exit 127
	fi
}

compile_python() {
	echo "compiling python..."
	PATH="$PROGS/bin:$PATH"
	SRCDIR="$SRC/$(basename "$CLVPYTHON" | rev | cut -d. -f3- | rev)"
	cd "$SRCDIR" || exit
	make clean
	CC=clang AR=llvm-ar LDFLAGS=-fuse-ld=lld ./configure --enable-optimizations --prefix="$PROGS"
	make -j "$(grep -c proc /proc/cpuinfo)"
	make install
}

download_all() {
	download_openjdk
	download_node
	download_vagrant
	download_llvm
	download_ninja
	download_cmake
	download_python
}


unpack_all() {
	test_progs_dir

	unpack_openjdk
	unpack_node
	unpack_vagrant
	unpack_llvm
	unpack_ninja
	unpack_cmake

	unpack_python
	compile_python
}

do_all() {
	download_all
	unpack_all
	create_archive
}

create_archive() {
	echo "creating tar archive..."
	if [ -d "$PROGS" ]
	then
		cd "$PROGS" || exit
		ARCHIVE="$ARCHIVES"/"$(basename "$PROGS")".tar.xz
		rm -f "$ARCHIVE"
		$TAR -Jcvf "$ARCHIVE" ./
	else
		do_all
	fi
}

create_archive
