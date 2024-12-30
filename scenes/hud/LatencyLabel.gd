extends Label
class_name LatencyLabel

var past_measurements := RingBuffer.new(16)

func _ready() -> void:
	past_measurements.fill(0)
	var timer := Timer.new()
	add_child(timer)
	timer.start(1.0)
	timer.connect("timeout", Callable(self, "_update_text"))

func update_latency(val: float):
	past_measurements.push(val)

func _update_text():
	var total := 0.0
	for i in range(past_measurements.size()):
		total += past_measurements.at(i)

	var avg := total / past_measurements.size()
	text = "%3.0fms" % (avg * 1000)
