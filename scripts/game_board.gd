extends Node2D
class_name GameBoard

var marble_prefab = preload("res://prefab_scenes/marble_prefab.tscn")
@onready var multiplayer_spawner = $MultiplayerSpawner


@export var points_container:PointsContainer
@export var lines_container:LinesContainer
@export var triangles_container:TrianglesContainer

@export var border_marbles:Array[Marble] = []
var black_marbles:Array[Marble] = []
var white_marbles:Array[Marble] = []
var shooting_marble:Marble

signal marble_added(black_marbles, white_marbles)
signal marble_shot(marble:Marble)


func _ready():
	reset_board()

func reset_board():
	$"/root/Lobby".print("reset_board() called")
	for line in lines_container.get_children():
		line.queue_free()
		
	for point in points_container.get_children():
		point.queue_free()
		
	for triangle in triangles_container.get_children():
		triangle.queue_free()
		
	for border in border_marbles:
		border.reset()

	white_marbles.clear()
	black_marbles.clear()
	# Ready for new points to be added

func init_next_marble(player_id):
	print($"/root/Lobby".player_info.name + ": init_next_marble() ")
	
	shooting_marble = marble_prefab.instantiate()
#	if $"/root/Lobby".player_info.color == player_id:
#		# defaults to network master of 1, or this server.
#		pass
#	else:
#		print($"/root/Lobby".player_info.name + ": setting marble network master to " + str($"/root/Lobby".guest_player_id))
#		shooting_marble.set_multiplayer_authority($"/root/Lobby".guest_player_id, true)
	points_container.add_child(shooting_marble, true)
	shooting_marble.freeze = true
	shooting_marble.collider.disabled = true
	shooting_marble.shadow.visible = false
	shooting_marble.trail_2d.visible = false
	if player_id == 0:
		black_marbles.append(shooting_marble)
	else:
		white_marbles.append(shooting_marble)
	shooting_marble.init(player_id, Vector2(10000, 0), black_marbles.size() + white_marbles.size())
	
	set_latest_marble_as_shooting.rpc(player_id)
	
@rpc("authority", "call_remote", "reliable")
func set_latest_marble_as_shooting(player_id:int):
	print($"/root/Lobby".player_info.name + ": set_latest_marble_as_shooting() ")
	shooting_marble = points_container.get_children().back()	
	shooting_marble.freeze = true
	shooting_marble.collider.disabled = true
	shooting_marble.shadow.visible = false
	shooting_marble.trail_2d.visible = false
	if player_id == 0:
		black_marbles.append(shooting_marble)
	else:
		white_marbles.append(shooting_marble)
		
	shooting_marble.init(player_id, shooting_marble.position, black_marbles.size() + white_marbles.size())
	print($"/root/Lobby".player_info.name + ": latest marble has index of " + str(shooting_marble.placed_index))
	
#	shooting_marble.init(player_id, Vector2(10000, 0), black_marbles.size() + white_marbles.size())
	print($"/root/Lobby".player_info.name + ": Marble init'ed for player " + str(shooting_marble.player))
	
func remove_unplaced_marble(player_id):
	points_container.remove_child(shooting_marble)
	if player_id == 0:
		black_marbles.remove_at(black_marbles.size() - 1)
	else:
		white_marbles.remove_at(black_marbles.size() - 1)
	shooting_marble.queue_free()
	
func move_shot_around_perimeter(pos):
#	var debug:String = "Moving Marble Around Perimeter from " + str(shooting_marble.position) + " to " + str(pos)
#	$"/root/Lobby".print(debug)
	shooting_marble.position = pos

func shoot(direction:Vector2, power:float):
	shooting_marble.freeze = false
	shooting_marble.collider.disabled = false
	shooting_marble.trail_2d.visible = true
	shooting_marble.is_shooting = true
	shooting_marble.apply_central_impulse(direction * power)
	marble_shot.emit(shooting_marble, power)
#	print("Marble shot")
	$"/root/Lobby".print("Marble Shot")
	
	

func start_territory_count():
	
	$"/root/Lobby".print("start_territory_count()")
	for line in lines_container.get_children():
		line.queue_free()
		
	for triangle in triangles_container.get_children():
		triangle.queue_free()
	
	marble_added.emit(black_marbles, white_marbles)

func _on_territory_count_triangle(tri:Territory.Tri):
	var p = PackedVector2Array()
	p.append(tri.triangle.a)
	p.append(tri.triangle.b)
	p.append(tri.triangle.c)
	
	var triP = Polygon2D.new()
	triP.polygon = p
	triP.color = Color(0.984, 0.961, 0.937, 0.25) if tri.owner == 1 else Color(0.153, 0.153, 0.267, 0.25)
	triangles_container.add_child(triP)
	
	# lines need the final point to be connected to the first manually
	p.append(tri.triangle.a)
	var line = Line2D.new()
	line.points = p
	line.width = 1
	line.antialiased = true
	line.default_color = Color(0.984, 0.961, 0.937) if tri.owner == 1 else Color(0.153, 0.153, 0.267)
	lines_container.add_child(line)
	


func _on_territory_show_triangle_lines(triangle, player):
	var p = PackedVector2Array()
	p.append(triangle.a)
	p.append(triangle.b)
	p.append(triangle.c)
	p.append(triangle.a)
	var line = Line2D.new()
	line.points = p
	line.width = 2
	line.antialiased = true
	line.default_color = Color(0.153, 0.153, 0.267, 0.4) if player == 0 else \
						 Color(0.984, 0.961, 0.937, 0.4) if player == 1 else \
						 Color(0.95, 0.827, 0.67, 0.4)
	lines_container.add_child(line)

func update_marbles_after_turn(): 
	for black in black_marbles:
		black.update_after_turn()
	for white in white_marbles:
		white.update_after_turn()
