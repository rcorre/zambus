#!/bin/sh -e

PROJECT="zambus"
FLAG=$([ $1 = --debug ] && echo "--export-debug" || echo "--export")

mkdir -p build/{linux,win32,win64}

./editor --no-window $FLAG linux build/linux/$PROJECT.x86_64
./editor --no-window $FLAG win64 build/win64/$PROJECT.exe
./editor --no-window $FLAG win32 build/win32/$PROJECT.exe

[ -f build/linux/libsteam_api.so ] || cp libsteam_api.so build/linux
[ -f build/win64/steam_api64.dll ] || cp steam_api64.dll build/win64
[ -f build/win32/steam_api.dll ] || cp steam_api.dll build/win32

cp steam_appid.txt build/linux
cp steam_appid.txt build/win64
cp steam_appid.txt build/win32

