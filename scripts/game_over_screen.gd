extends Control
class_name GameOverScreen

@export var winner_label:Label
@export var black_score_label:Label
@export var white_score_label:Label

func set_scores(black_score:float, white_score:float):
	if black_score > white_score:
		winner_label.text = "BLACK wins!"
	elif white_score > black_score:
		winner_label.text = "WHITE wins!"
	else:
		winner_label.text = "TIE, somehow? Lol floating points."
		
	black_score_label.text = "BLACK: " + str(round(black_score / 100)) + " points."
	white_score_label.text = "WHITE: " + str(round(white_score / 100)) + " points."

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
