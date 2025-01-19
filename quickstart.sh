#!/bin/bash -e

GODOT_FLAGS=""
GAME_FLAGS=""

GUEST_COUNT=${1:-1}
shift

while [[ $# > 0 ]] && [[ "$1" != '--' ]]; do
	GODOT_FLAGS="$GODOT_FLAGS $1"
	shift
done

[[ "$1" == '--' ]] && shift 
GAME_FLAGS="$@"

GODOT_BIN="godot -d $GODOT_FLAGS"

trap "kill -s TERM 0" SIGINT

$GODOT_BIN test/QuickStart.tscn host $GAME_FLAGS 2>&1 | tee "/tmp/host.log" &

for i in $(seq $GUEST_COUNT); do
		sleep 1
    $GODOT_BIN test/QuickStart.tscn join $GAME_FLAGS 2>&1 | tee "/tmp/peer$i.log" &
done

wait

if [[ $* == *--debug-network* ]]; then
	grep Server /tmp/host.log | cut -d'|' -f2- | sort -n | uniq > /tmp/host.txt
	for i in $(seq $GUEST_COUNT); do
		grep Client "/tmp/peer$i.log" | cut -d'|' -f2- | sort -n > "/tmp/peer$i.txt"
	done

	nvim -d /tmp/host.txt /tmp/peer1.txt
fi
