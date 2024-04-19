extends RigidBody2D
class_name Marble

@export var sprite:Sprite2D
@export var collider:CollisionShape2D
@export var shadow:Sprite2D

var player:int
var placed_index:int
var border_marble:bool

var is_move_manually
var move_manually_to

var stable:bool
var turns_until_stable:int
var STABILITY_TURNS:int = 8

var nearest_marbles:Array[Marble] = []

func init(placing_player:int, placed_position:Vector2, index:int):
	sprite.modulate = Color(0, 0, 0) if placing_player == 0 else Color(1, 1, 1)
	player = placing_player
	position = placed_position
	placed_index = index
	stable = false
	turns_until_stable = STABILITY_TURNS
	nearest_marbles = []
	
func _integrate_forces(state):
	if is_move_manually:
		is_move_manually = false
		state.transform = Transform2D(0, move_manually_to)	

func move_manually(move_to:Vector2):
	move_manually_to = move_to
	is_move_manually = true

func update_after_turn():
	# handle captures prior to this function call.
	if stable:
		return
		
	turns_until_stable -= 1
	if turns_until_stable <= 0:
		stable = true
		self.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		self.freeze = true
		shadow.visible = false
	else:
		var nearest_opponent_count = nearest_marbles.filter(func(m): return m != null && m.player != player).size()
		print("Unstable marble " + str(player) + ", " + str(placed_index) + " has a danger of " + str(nearest_opponent_count))
		if nearest_marbles.size() == 4 && nearest_opponent_count >= 3:
			shadow.modulate = Color(0.776, 0.623, 0.647, 1)
		elif nearest_marbles.size() == 4 && nearest_opponent_count == 2:
			shadow.modulate = Color(0.776, 0.623, 0.647, 0.25)
		else:
			shadow.modulate = Color(1, 1, 1, 0.25)
			
		
