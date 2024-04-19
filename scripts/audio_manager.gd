extends Node
class_name AudioManager

var ClickSound = preload("res://audio/click.wav")
@export var whiteSounds : Array[AudioStream]
@export var blackSounds : Array[AudioStream]

var rng = RandomNumberGenerator.new()

@export var audioStreamPlayers: Array[AudioStreamPlayer2D]

var currentPlayer = 0
var nextIdx = 0
func playSound(sound : AudioStream, random_scale : float = 0.0) -> void:
	var audioStreamPlayer = audioStreamPlayers[currentPlayer % audioStreamPlayers.size()]
	currentPlayer = currentPlayer + 1
	
	audioStreamPlayer.stream = sound
	if (random_scale > 0.0):
		audioStreamPlayer.pitch_scale = rng.randf_range(1.0 - random_scale, 1.0 + random_scale)
	else:
		audioStreamPlayer.pitch_scale = 1.0 
	audioStreamPlayer.play()
		
func playArraySound(sounds : Array, idx : int) -> void:
	playSound(sounds[idx], 0.0)

func playWhiteSound(idx : int) -> void:
	playArraySound(whiteSounds, idx % whiteSounds.size())

func playBlackSound(idx : int) -> void:
	playArraySound(blackSounds, idx % blackSounds.size())
	
func playClick() -> void:
	playSound(ClickSound, 0.2)


func _on_territory_count_triangle(_triangle:Delaunay.Triangle, player:int):
	if (player == 0):
		playWhiteSound(nextIdx)
	else:
		playBlackSound(nextIdx)
	nextIdx = nextIdx + 1

func _on_game_board_marble_added(_black_marbles, _white_marbles):
	playClick()


func _on_game_board_marble_shot(_marble : Marble):
	playClick()
