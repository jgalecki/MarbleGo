extends Camera2D
class_name Camera

@export var camera_offset:Vector2

var shake_duration: float
@onready var rand = RandomNumberGenerator.new()
var shake_strength: float
var shake_duration_original: float

# Called when the node enters the scene tree for the first time.
func _ready():
	camera_offset = Vector2(0, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position = position.lerp(position + camera_offset, delta * 8)

	if shake_strength > 0:
		print("Shaking w/ strength " + str(shake_strength))
		# Fade out the intensity over time
		shake_strength = lerpf(0, shake_strength, shake_duration / shake_duration_original)
		shake_duration -= delta
		

		# Shake by adjusting camera.offset so we can move the camera around the level via it's position
		camera_offset = Vector2(
			rand.randf_range(-shake_strength, shake_strength),
			rand.randf_range(-shake_strength, shake_strength)
		)
	else:
		if position.length() < 1:
			camera_offset = Vector2.ZERO
		else:
			camera_offset = -1 * position

func shake(amplitude:float, time:float):
	shake_strength = amplitude
	shake_duration = time
	shake_duration_original = time
