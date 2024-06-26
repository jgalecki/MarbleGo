extends Node
class_name Ai

# Return a vector2 with the initial position of the marble to be shot.
# The return vector will be normalized and placed on the border of the board 
# (a circle with radius 256).  
func place_marble(blacks:Array[Marble], whites:Array[Marble], borders:Array[Marble]) -> Vector2:
	return Vector2.ZERO

# Return a float, will be clamped between [0, 1]
func shoot_marble_power() -> float:
	return 0
	
# Return a float representing the angle, in degrees, for the direction of the
# marble shot. The return vector will be normalized.
# [1, 0] -> right
# [0, -1] -> up
# [-1, 0] -> left
# [0, 1] -> down
func shoot_marble_angle() -> Vector2:	
	return Vector2.ZERO

func ai_handicap() -> int:
	return 0
