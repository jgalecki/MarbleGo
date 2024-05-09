extends Node
class_name AudioManager

var ClickSound = preload("res://audio/click.wav")
var PlinkSound = preload("res://audio/plink_1.wav")
var ShotSound = preload("res://audio/shot_1.wav")
var BlipSound = preload("res://audio/blip_1.wav")
var ArpSound = preload("res://audio/arpeggio.wav")
var HitSound = preload("res://audio/hit_1.wav")
var CaptureSound = preload("res://audio/capture.wav")

@export var whiteSounds : Array[AudioStream]
@export var blackSounds : Array[AudioStream]

var rng = RandomNumberGenerator.new()

@export var audioStreamPlayers: Array[AudioStreamPlayer2D]

var currentPlayer = 0
var nextIdx = 0
var anyCapturedThisFrame = false

func _process(delta):
	if anyCapturedThisFrame:
		playCapture(1.0)
		anyCapturedThisFrame = false

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
	playSound(ClickSound, 0.2, 1.5)

func playShot(volume : float) -> void:
	playSound(ShotSound, 0.2, volume)

func playPlink(volume : float) -> void:
	playSound(PlinkSound, 0.2, volume)

func playBlip(volume : float) -> void:
	playSound(BlipSound, 0.2, volume)

func playHit(volume : float) -> void:
	playSound(HitSound, 0.2, volume)

func playArp(volume : float) -> void:
	playSound(ArpSound, 0.0, volume)

func playCapture(volume : float) -> void:
	playSound(CaptureSound, 0.0, volume)


func _on_territory_count_triangle(triangle):
	if (triangle.owner == 0):
		playWhiteSound(nextIdx)
	else:
		playBlackSound(nextIdx)
	nextIdx = nextIdx + 1

func _on_game_board_marble_added(_black_marbles, _white_marbles):
	print("audo: marble added")
	playArp(1.0)

func _on_marble_collision(marble : Marble, isBig : bool):
	var bigVel = 300.0
	var smallVel = 80.0
	var clampVel = 50.0
	var minVolume = 0.1
	var maxVolume = 1.1
	var vel = marble.linear_velocity.length()
	# Do not make sounds for tiny collisions.
	if vel < clampVel:
		return
	if isBig:
		# Big gets a hit.
		playHit(min(max(vel / bigVel, minVolume), maxVolume))
	else:
		# Small gets a plink
		playPlink(min(max(vel /smallVel, minVolume), maxVolume))

func _on_game_board_marble_shot(marble : Marble, velocity : float):
	playShot(min(max(velocity / 750.0, 0.2), 1.0))
	marble.on_collision.connect(_on_marble_collision, 0)

func _on_game_board_marble_captured(marble : Marble):
	anyCapturedThisFrame = true
