extends Node2D
class_name GameBoard

var marble_prefab = preload("res://prefab_scenes/marble.tscn")

# References to child nodes for drawing
@export var points_container:PointsContainer
@export var lines_container:LinesContainer
@export var triangles_container:TrianglesContainer
@export var audio_manager:AudioManager

# Store the points added by players
var black_marbles:Array[Marble] = []
var white_marbles:Array[Marble] = []


# Signal to notify when a point is added (for recalculating territories, for example)
signal marble_added(black_marbles, white_marbles)

func _ready():
	reset_board()

func reset_board():
	# Clear existing points, lines, and triangles
#	pointsContainer.clear() # Assume a clear method exists to remove drawn points
#	linesContainer.clear() # Similarly, clear drawn lines
#	trianglesContainer.clear() # Clear shaded triangles

	for line in lines_container.get_children():
		line.queue_free()
		
	for point in points_container.get_children():
		point.queue_free()
		
	for triangle in triangles_container.get_children():
		triangle.queue_free()

	white_marbles.clear()
	black_marbles.clear()
	# Ready for new points to be added

func add_point(player_id, position) -> bool:
	# Add the point to the list
	var marble = marble_prefab.instantiate()
	points_container.add_child(marble)
	marble.init(player_id, position)
	if player_id == 0:
		black_marbles.append(marble)
	else:
		white_marbles.append(marble)
	
	for line in lines_container.get_children():
		line.queue_free()
		
	for triangle in triangles_container.get_children():
		triangle.queue_free()
	
	marble_added.emit(black_marbles, white_marbles)
	audio_manager.playClick()
	
	# Draw the point
#	draw_point(position, player_id)
#
#	# Emit signal to recalculate territories
#	emit_signal("marble_added", position, player_id)
	
	# You could also directly call a method to recalculate territories here
	# and then update the UI accordingly
	return true

#func draw_point(position, player_id):
#	var color = Color(0, 0, 0) if player_id == 0 else Color(1, 1, 1)
#	var point = CircleShape2D.new()
#	point.radius = 5
##	point.position = position
##	point.color = color
#	var collider = CollisionShape2D.new() # Assuming a method to add children dynamically
#	collider.reparent(pointsContainer)
#	collider.shape = point
#	collider.position = position
#	collider.color = color

# Placeholder method to draw lines between points
func draw_lines():
	# This method would iterate over the points list and draw lines between them
	# according to the rules of your game (e.g., Delaunay triangulation)
	pass

# Placeholder method to draw shaded triangles
func draw_triangles():
	# This method would handle drawing shaded triangles based on the calculated
	# territories. It would use the triangulation data to determine which points
	# form each triangle and then shade them accordingly.
	pass


func _on_territory_count_triangle(triangle: Delaunay.Triangle, player: int, count : int):
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
	if player == 0:
		audio_manager.playBlackSound(count)
	else:
		audio_manager.playWhiteSound(count)
	


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
	line.default_color = Color(0, 0, 0, 0.2) if player == 0 else Color(1, 1, 1, 0.2)
	lines_container.add_child(line)
