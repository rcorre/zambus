extends RefCounted
class_name RingBuffer

var data: Array
var idx := 0

func _init(new_size: int):
	data.resize(new_size)

func push(v):
	idx = (idx + 1) % data.size()
	data[idx] = v

func at(offset: int):
	assert(offset < data.size())
	return data[(idx - offset) % data.size()]

# returns an array [at(n-1), at(n-2), ..., at(1), at(0)]
func slice(n: int) -> Array:
	var res := []
	if n > data.size():
		push_error("RingBuf.slice: %d (n) > %d (size)" % [n, data.size()])
		n = data.size()
	res.resize(n)
	for i in range(n):
		res[i] = at(i)
	return res

func put(offset: int, v):
	assert(offset < data.size())
	data[(idx - offset) % data.size()] = v

func fill(v):
	for i in range(data.size()):
		data[i] = v

func size() -> int:
	return data.size()

func _to_string() -> String:
	var ret := "["
	for i in range(data.size()):
		ret += "%s," % at(i)
	ret[ret.length() - 1] = "]"
	return ret
