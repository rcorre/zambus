extends Node

enum CollisionLayer {
	DEFAULT  = 1 << 0,
	PLAYER   = 1 << 1,
	NPC      = 1 << 2,
	INTERACT = 1 << 3,
	WEAPON   = 1 << 4,
	GUARD    = 1 << 5,
	HITBOX   = 1 << 6,
}

# Every SERVER_STEP frames, we process peer inputs, re-simulate, and send out new states to peers
# 3 frames at 60fps is a 50ms step
const SERVER_STEP := 3
const SERVER_STEP_DURATION := SERVER_STEP / 60.0

# Angle within which attacks are blocked per point of guard
# For example, a guard value of 8 blocks attacks in a PI/8 arc
const GUARD_ANGLE := PI / 32.0

# Called by Player class
@warning_ignore("UNUSED_SIGNAL")
signal local_player_spawned(player: Player)

# Set from Game, just used for easy access in print messages
var current_frame: int
