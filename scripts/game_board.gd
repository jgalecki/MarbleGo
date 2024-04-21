extends Node2D
class_name GameBoard

var marble_prefab = preload("res://prefab_scenes/marble_prefab.tscn")

@export var points_container:PointsContainer
@export var lines_container:LinesContainer
@export var triangles_container:TrianglesContainer

@export var border_marbles:Array[Marble] = []
var black_marbles:Array[Marble] = []
var white_marbles:Array[Marble] = []
var shooting_marble:Marble
var last_turn_marble:Marble

signal marble_added(black_marbles, white_marbles)
signal marble_shot(marble:Marble)

func _ready():
	reset_board()

func reset_board():
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
	last_turn_marble = null
	# Ready for new points to be added

func next_turn(player_id):
	shooting_marble = marble_prefab.instantiate()
	points_container.add_child(shooting_marble)
	shooting_marble.freeze = true
	shooting_marble.collider.disabled = true
	if player_id == 0:
		black_marbles.append(shooting_marble)
	else:
		white_marbles.append(shooting_marble)
	shooting_marble.init(player_id, Vector2(10000, 0), black_marbles.size() + white_marbles.size())
	
func remove_unplaced_marble(player_id):
	points_container.remove_child(shooting_marble)
	if player_id == 0:
		black_marbles.remove_at(black_marbles.size() - 1)
	else:
		white_marbles.remove_at(black_marbles.size() - 1)
	shooting_marble.queue_free()
	
func move_shot_around_perimeter(position):
	shooting_marble.position = position

func shoot(direction:Vector2, power:float):
	shooting_marble.freeze = false
	shooting_marble.collider.disabled = false
	shooting_marble.apply_central_impulse(direction * power)
	marble_shot.emit(shooting_marble, power)

func start_territory_count():
	
	for line in lines_container.get_children():
		line.queue_free()
		
	for triangle in triangles_container.get_children():
		triangle.queue_free()
	
	marble_added.emit(black_marbles, white_marbles)

func _on_territory_count_triangle(triangle: Delaunay.Triangle, player: int):
	var p = PackedVector2Array()
	p.append(triangle.a)
	p.append(triangle.b)
	p.append(triangle.c)
	
	var tri = Polygon2D.new()
	tri.polygon = p
	tri.color = Color(0, 0, 0, 0.25) if player == 0 else Color(1, 1, 1, 0.25)
	triangles_container.add_child(tri)
	
	# lines need the final point to be connected to the first manually
	p.append(triangle.a)
	var line = Line2D.new()
	line.points = p
	line.width = 1
	line.antialiased
	line.default_color = Color(0, 0, 0) if player == 0 else Color(1, 1, 1)
	lines_container.add_child(line)
	


func _on_territory_show_triangle_lines(triangle, player):
	var p = PackedVector2Array()
	p.append(triangle.a)
	p.append(triangle.b)
	p.append(triangle.c)
	p.append(triangle.a)
	var line = Line2D.new()
	line.points = p
	line.width = 1
	line.antialiased
	line.default_color = Color(0, 0, 0, 0.4) if player == 0 else \
						 Color(1, 1, 1, 0.4) if player == 1 else \
						 Color(0.95, 0.827, 0.67, 0.6) if player == 2 else \
						 Color(0.286, 0.302, 0.494, 0.6) # neutral lines / triangles
	lines_container.add_child(line)

func update_marbles_after_turn():
	for black in black_marbles:
		black.update_after_turn()
	for white in white_marbles:
		white.update_after_turn()
