extends Node

func _ready() -> void:
	var input := StreamPeerBuffer.new()
	var val := (1 << 31 ) + 42
	input.put_u32(val)
	var output := StreamPeerBuffer.new()
	output.data_array = input.data_array
