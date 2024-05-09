extends Control
class_name ScoreDisplay

@export var current_turn:Label
@export var score:Label
@export var mouse_position:Label


func update_scores(scores:Array[float], turn:int, current_player:int):
	current_turn.text = ("Black" if current_player == 0 else "White") + " " + str(turn)
	score.text = "Black: " + str(round(scores[0]) / 100) + ", White: " + str(round(scores[1]) / 100)
#	$"/root/Lobby".print("Black: " + str(round(scores[0]) / 100) + ", White: " + str(round(scores[1]) / 100))
	
func update_mouse(phase:int, mouse:Vector2):
	var phase_str = ""
	match phase:
		0:
			phase_str = "Placing"
		1: 
			phase_str = "Shooting"
		2: 
			phase_str = "Rolling"
		3:
			phase_str = "Calculating"
	
	mouse_position.text = phase_str
