#!/bin/sh

CURL="$(which curl 2>/dev/null)"
KERN="$(uname -s)"
LOWERKERN="$(echo "$KERN" | tr '[:upper:]' '[:lower:]')"
MACH="$(uname -m)"
ARCHIVES="$(pwd)/archives"
CLVOJDK=""
CLVNODE=""
CLVVAGRANT=""
CLVLLVM=""

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

download_node() {
	URL="https://nodejs.org"
	LATESTLTS="$($CURL -s "$URL/dist/" | grep "latest-v..\." | cut -d"=" -f2 | cut -d">" -f1 | tr -d \"/ | sort | tail -n3 | head -n1 )"
	ENDPOINT="$($CURL -s "$URL/dist/$LATESTLTS/" | grep node | grep xz | grep $LOWERKERN | grep $MACH | cut -d">" -f1 | cut -d= -f2 | tr -d \")"
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

download_vagrant() {
	URL="https://releases.hashicorp.com"
	LATEST="$($CURL -s "$URL/vagrant/" | grep vagrant_ | head -n1 | awk -F\" '{print $2}')"
	LINK="$($CURL -s "$URL$LATEST" | grep $LOWERKERN | grep zip | cut -d">" -f1 | rev | cut -d= -f1 | rev | tr -d \")"
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

download_openjdk
download_node
download_vagrant
download_llvm
