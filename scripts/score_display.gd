extends Control
class_name ScoreDisplay

@export var current_turn:Label
@export var score:Label
@export var mouse_position:Label


func update_scores(scores:Array[float], moves_left:int, current_player:int):
	current_turn.text = "Black" if current_player == 0 else "White"
	score.text = "Black: " + str(round(scores[0]) / 100) + ", White: " + str(round(scores[1]) / 100)
	print("Black: " + str(round(scores[0]) / 100) + ", White: " + str(round(scores[1]) / 100))
	
func update_mouse(mouse:Vector2):
	var on_circle = " x" if mouse.distance_to(Vector2.ZERO) < 256 else ""
	mouse_position.text = "X: " + str(mouse.x) + ", Y: " + str(mouse.y) + on_circle
