extends Marble
class_name BorderMarble

var flag_to_claim:bool

# Called when the node enters the scene tree for the first time.
func _ready():
	reset()

func reset():
	player = -1
	nearest_marbles = []
	stable = false
	flag_to_claim = false
	sprite.modulate = Color(0.95, 0.83, 0.67)
	border_marble = true

func update_after_turn():
	if stable:
		return
	var black_count = nearest_marbles.filter(func(m): return m != null && m.player == 0).size()
	var white_count = nearest_marbles.filter(func(m): return m != null && m.player == 1).size()
	if black_count == 5:
		stable = true
		spawn_stabalize_particles()
		camera.shake(500, 1)
		player = 0
		sprite.modulate = Color(0.153, 0.153, 0.267)
		flag_to_claim = true
	elif white_count == 5:
		stable = true
		spawn_stabalize_particles()
		camera.shake(500, 1)
		player = 1
		sprite.modulate = Color(0.984, 0.961, 0.937)
		flag_to_claim = true
