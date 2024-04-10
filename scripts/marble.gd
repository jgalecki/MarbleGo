extends Node2D
class_name Marble

@export var sprite:Sprite2D
@export var collider:CollisionShape2D

var player:int

func init(placing_player:int, placed_position:Vector2):
	sprite.modulate = Color(0, 0, 0) if placing_player == 0 else Color(1, 1, 1)
	player = placing_player
	position = placed_position
