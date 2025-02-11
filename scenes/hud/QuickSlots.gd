extends HBoxContainer

var player: Player

func _ready() -> void:
	set_process(false)
	Global.local_player_spawned.connect(set_player)

func set_player(p: Player) -> void:
	player = p
	p.inventory_changed.connect(on_inventory_changed)

func on_inventory_changed() -> void:
	for i in get_child_count():
		var item := Item.ID.NONE
		if i < player.inventory.size():
			item = player.inventory[i]
		var button: Button = get_child(i).get_node("Button") as Button
		button.icon = Item.load_icon(item)
