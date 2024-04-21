extends Node
class_name AudioManager

var ClickSound = preload("res://audio/click.wav")
var PlinkSound = preload("res://audio/plink_1.wav")
var ShotSound = preload("res://audio/shot_1.wav")

@export var whiteSounds : Array[AudioStream]
@export var blackSounds : Array[AudioStream]

var rng = RandomNumberGenerator.new()

@export var audioStreamPlayers: Array[AudioStreamPlayer2D]

var currentPlayer = 0
var nextIdx = 0

func linear2db(volume : float) -> float:
	return (0 + 30) * volume - 30

func playSound(sound : AudioStream, random_scale : float = 0.0, volume : float = 1.0) -> void:
	var audioStreamPlayer = audioStreamPlayers[currentPlayer % audioStreamPlayers.size()]
	currentPlayer = currentPlayer + 1
	
	audioStreamPlayer.stream = sound
	if (random_scale > 0.0):
		audioStreamPlayer.pitch_scale = rng.randf_range(1.0 - random_scale, 1.0 + random_scale)
	else:
		audioStreamPlayer.pitch_scale = 1.0 
		
	audioStreamPlayer.volume_db = linear2db(volume)
	audioStreamPlayer.play()
		
func playArraySound(sounds : Array, idx : int) -> void:
	playSound(sounds[idx], 0.0)

func playWhiteSound(idx : int) -> void:
	playArraySound(whiteSounds, idx % whiteSounds.size())

func playBlackSound(idx : int) -> void:
	playArraySound(blackSounds, idx % blackSounds.size())
	
func playClick() -> void:
	playSound(ClickSound, 0.2)

func playShot(volume : float) -> void:
	playSound(ShotSound, 0.2, volume)


func playPlink(volume : float) -> void:
	playSound(PlinkSound, 0.2, volume)

func _on_territory_count_triangle(triangle):
	if (triangle.owner == 0):
		playWhiteSound(nextIdx)
	else:
		playBlackSound(nextIdx)
	nextIdx = nextIdx + 1

func _on_game_board_marble_added(_black_marbles, _white_marbles):
	playClick()


func _on_body_entered(_body, marble : Marble):
	# Play a plink noise whenever the body collides.
	playPlink(min(max(marble.linear_velocity.length() / 300.0, 0.2), 2.0))

func _on_game_board_marble_shot(marble : Marble, velocity : float):
	playShot(min(max(velocity / 750.0, 0.2), 1.0))
	var body_entered_lambda = func(x) : return _on_body_entered(x, marble)
	marble.body_entered.connect(body_entered_lambda, 0)
