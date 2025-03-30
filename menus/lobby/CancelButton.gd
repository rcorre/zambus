extends Button

func _pressed() -> void:
	# Lobby will catch the signal from this and exit to Title
	Net.quit()
