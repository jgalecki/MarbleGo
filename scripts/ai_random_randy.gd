extends Ai
class_name AI_Random_Randy

var rng = RandomNumberGenerator.new()
var handicap = 1000

# Return a vector2 with the initial position of the marble to be shot.
# The return vector will be normalized and placed on the border of the board 
# (a circle with radius 256).  
func place_marble(blacks:Array[Marble], whites:Array[Marble], borders:Array[Marble]) -> Vector2:
	var place = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
	print("Random placement: " + str(place))
	return place

# Return a float, will be clamped between [0, 1]
func shoot_marble_power() -> float:
	var power = rng.randf_range(0, 1)
	print("Random shot power: " + str(power))
	return power
	
# Return a float representing the angle, in degrees, for the direction of the
# marble shot. 
# 0 -> [1, 0], right
# 90 -> [0, -1], up
# 180 -> [-1, 0], left
# 270 -> [0, 1], down
func shoot_marble_angle() -> float:	
	var angle = rng.randf_range(0, 360)
	print("Random shot angle: " + str(angle))
	return angle

func ai_handicap() -> int:
	return 1000
