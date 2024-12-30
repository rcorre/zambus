extends MainLoop

var failed := false

func expect_eq(a, b):
	if a != b:
		printerr("%s != %s" % [a, b])
		failed = true

func expect_ne(a, b):
	if a == b:
		printerr("%s == %s" % [a, b])
		failed = true

func _physics_process(_delta: float) -> bool:
	return true  # exit immediately

func _initialize():
	test_player_state()
	test_player_input()

func test_player_state():
	var expected := PlayerState.new()
	expected.pos = Vector3(1, 2, 3)
	expected.vel = Vector3(4, 5, 6)
	expected.look = Vector2(7, 8)
	expected.stance = Stance.ATTACK | Stance.DODGE
	expected.health = 15
	expected.hits = [17179869184,164384]
	expected.status[1] = 2
	expected.status[3] = 4

	var buf_in := StreamPeerBuffer.new()
	expected.write(buf_in)

	var buf_out := StreamPeerBuffer.new()
	buf_out.data_array = buf_in.data_array

	var actual := PlayerState.new(buf_out)
	expect_eq(buf_out.get_available_bytes(), 0)
	expect_eq(actual.pos, expected.pos)
	expect_eq(actual.vel, expected.vel)
	expect_eq(actual.look, expected.look)
	expect_eq(actual.stance, expected.stance)
	expect_eq(actual.health, expected.health)
	expect_eq(actual.hits, expected.hits)
	expect_eq(actual.status, expected.status)

	var dup: PlayerState = expected.clone()
	expect_eq(dup.pos, expected.pos)
	expect_eq(dup.vel, expected.vel)
	expect_eq(dup.look, expected.look)
	expect_eq(dup.stance, expected.stance)
	expect_eq(dup.health, expected.health)
	expect_eq(dup.hits, expected.hits)
	expect_eq(dup.status, expected.status)

	# Ensure the dup is not mutated when the original is
	expected.pos = Vector3(1, 3, 3)
	expected.vel = Vector3(3, 5, 6)
	expected.look = Vector2(6, 7)
	expected.stance = Stance.DODGE
	expected.health = 12
	expected.hits.push_back(123)
	expected.status[1] = 8

	expect_ne(dup.pos, expected.pos)
	expect_ne(dup.vel, expected.vel)
	expect_ne(dup.look, expected.look)
	expect_ne(dup.stance, expected.stance)
	expect_ne(dup.health, expected.health)
	expect_ne(dup.hits, expected.hits)
	expect_ne(dup.status, expected.status)

	print("test_player_state " + ("FAIL" if failed else "PASS"))

func test_player_input():
	var expected := PlayerInput.new()
	expected.move = Vector2(1, 2)
	expected.look = Vector2(7, 8)
	expected.stance = Stance.CROUCH | Stance.ATTACK

	var buf_in := StreamPeerBuffer.new()
	expected.write(buf_in)

	var buf_out := StreamPeerBuffer.new()
	buf_out.data_array = buf_in.data_array

	var actual := PlayerInput.new(buf_out)
	expect_eq(actual.move, expected.move)
	expect_eq(actual.look, expected.look)
	expect_eq(actual.stance, expected.stance)
	expect_eq(buf_out.get_available_bytes(), 0)

	var dup: PlayerInput = expected.duplicate()
	expect_eq(dup.move, expected.move)
	expect_eq(dup.look, expected.look)
	expect_eq(dup.stance, expected.stance)

	# Ensure the dup is not mutated when the original is
	expected.move = Vector2(2, 3)
	expected.look = Vector2(8, 9)
	expected.stance = 0
	expect_ne(dup.move, expected.move)
	expect_ne(dup.look, expected.look)
	expect_ne(dup.stance, expected.stance)

	print("test_player_input " + ("FAIL" if failed else "PASS"))
