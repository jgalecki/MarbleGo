extends Node2D
class_name Territory

#===================================
class Tri:
	var owner:int
	var index:int
	var triangle:Delaunay.Triangle
	
	func _init(owner:int, index:int, triangle:Delaunay.Triangle):
		self.owner = owner
		self.index = index
		self.triangle = triangle
#===================================

var black_delaunay:Delaunay
var white_delaunay:Delaunay

signal count_triangle(triangle:Delaunay.Triangle, player:int, triangle_idx:int)
signal show_triangle_lines(triangle:Delaunay.Triangle, player:int)
signal finished_scoring()

func _init():
	black_delaunay = Delaunay.new(Rect2(-128, -128, 256, 256))
	white_delaunay = Delaunay.new(Rect2(-128, -128, 256, 256))

func _on_marble_added(black_marbles:Array[Marble], white_marbles:Array[Marble]):
	black_delaunay = Delaunay.new(Rect2(-128, -128, 256, 256))
	white_delaunay = Delaunay.new(Rect2(-128, -128, 256, 256))
	for marble in black_marbles:
		black_delaunay.add_point(marble.position)
		
	for marble in white_marbles:
		white_delaunay.add_point(marble.position)
	
	var black_triangles = black_delaunay.triangulate()
	var black_tris:Array[Tri] = []
	for i in range(black_triangles.size()):
		black_tris.append(Tri.new(0, i, black_triangles[i]))
	
	var white_triangles = white_delaunay.triangulate()
	var white_tris:Array[Tri] = []
	for i in range(white_triangles.size()):
		white_tris.append(Tri.new(1, i, white_triangles[i]))
		
	var unblocked_tris:Array[Tri] = []
	
	for black_tri in black_tris:
		if black_delaunay.is_border_triangle(black_tri.triangle): continue
		show_triangle_lines.emit(black_tri.triangle, 0)
		await get_tree().create_timer(0.1).timeout
		if opponent_in_triangle(black_tri.triangle, white_marbles): 
#			show_triangle_lines.emit(black_tri.triangle, 0)
			continue
		unblocked_tris.append(black_tri)
		
	for white_tri in white_tris:
		if white_delaunay.is_border_triangle(white_tri.triangle): continue
		show_triangle_lines.emit(white_tri.triangle, 1)
		await get_tree().create_timer(0.1).timeout
		if opponent_in_triangle(white_tri.triangle, black_marbles): 
#			show_triangle_lines.emit(white_tri.triangle, 1)
			continue
		unblocked_tris.append(white_tri)
#		count_triangle.emit(white_tri, 1)

	unblocked_tris.sort_custom(sort_longer_longest_side)
	var black_count :int  = 0
	var white_count: int = 0
	while unblocked_tris.size() > 0:
		var tri = unblocked_tris[0]
		unblocked_tris.remove_at(0)
		var remove_is = []
		for i in range(unblocked_tris.size()):
			var other_tri = unblocked_tris[i]
			if tri.owner != other_tri.owner && triangle_intersets(tri.triangle, other_tri.triangle):
				remove_is.append(i)
				
		remove_is.reverse()
		for i in remove_is:
			var removing_tri = unblocked_tris[i]
			show_triangle_lines.emit(removing_tri.triangle, removing_tri.owner)
			unblocked_tris.remove_at(i)
		var count = black_count
		if tri.owner == 1:
			count = white_count
		count_triangle.emit(tri.triangle, tri.owner, count)
		if tri.owner == 0:
			black_count = black_count + 1
		else:
			white_count = white_count + 1
		await get_tree().create_timer(0.15).timeout
	
	finished_scoring.emit()

func opponent_in_triangle(tri:Delaunay.Triangle, marbles:Array[Marble]) -> bool:
	for marble in marbles:
		if point_in_triangle(marble.position, tri.a, tri.b, tri.c):
			return true
	return false
		
func point_in_triangle(pt:Vector2, tri_a:Vector2, tri_b:Vector2, tri_c:Vector2) -> bool:
	var d1 = tri_sign(pt, tri_a, tri_b);
	var d2 = tri_sign(pt, tri_b, tri_c);
	var d3 = tri_sign(pt, tri_c, tri_a);

	var has_neg = (d1 < 0) || (d2 < 0) || (d3 < 0);
	var has_pos = (d1 > 0) || (d2 > 0) || (d3 > 0);

	return !(has_neg && has_pos);
	
func tri_sign(p1:Vector2, p2:Vector2, p3:Vector2) -> float:
	return (p1.x - p3.x) * (p2.y - p3.y) - (p2.x - p3.x) * (p1.y - p3.y);

func sort_longer_longest_side(tri_a:Tri, tri_b:Tri) -> bool:
	var longest_a = maxf(tri_a.triangle.edge_ab.length(), \
						maxf(tri_a.triangle.edge_bc.length(), tri_a.triangle.edge_ca.length()))
	var longest_b = maxf(tri_b.triangle.edge_ab.length(), \
						maxf(tri_b.triangle.edge_bc.length(), tri_b.triangle.edge_ca.length()))
	return longest_a < longest_b

func triangle_intersets(triangle_a:Delaunay.Triangle, triangle_b:Delaunay.Triangle) -> bool:
	var a_edges:Array[Delaunay.Edge] = [triangle_a.edge_ab, triangle_a.edge_bc, triangle_a.edge_ca]
	var b_edges:Array[Delaunay.Edge] = [triangle_b.edge_ab, triangle_b.edge_bc, triangle_b.edge_ca]
	for ai in range(3):
		for bi in range(3):
			if line_segments_intersect(a_edges[ai].a, a_edges[ai].b, b_edges[bi].a, b_edges[bi].b):
				return true
	return false
	
	
#func line_segments_intersect(p1, q1, p2, q2):
func line_segments_intersect(a1, a2, b1, b2):
	# Calculate the four orientations needed for the general and special cases
	var o1 = orientation(a1, a2, b1)
	var o2 = orientation(a1, a2, b2)
	var o3 = orientation(b1, b2, a1)
	var o4 = orientation(b1, b2, a2)
	
	# Special Cases
	# a1, a2, and b1 are collinear and b1 lies on segment a1a2
	if o1 == 0 and on_segment(a1, b1, a2): return true
	# a1, a2, and b2 are collinear and b2 lies on segment a1a2
	if o2 == 0 and on_segment(a1, b2, a2): return true
	# b1, b2, and a1 are collinear and a1 lies on segment b1b2
	if o3 == 0 and on_segment(b1, a1, b2): return true
	# b1, b2, and a2 are collinear and a2 lies on segment b1b2
	if o4 == 0 and on_segment(b1, a2, b2): return true
	
	# General case
	if o1 != o2 and o3 != o4:
		return true
	
	# Doesn't fall in any of the above cases
	return false

# Utility function to find orientation of ordered triplet (p, q, r).
# The function returns the following values:
# 0 --> p, q, and r are collinear
# 1 --> Clockwise
# 2 --> Counterclockwise
func orientation(p, q, r):
	var val = (q.y - p.y) * (r.x - q.x) - (q.x - p.x) * (r.y - q.y)
	if val == 0: return 0  # Collinear
	return 1 if val > 0 else 2  # Clock or counterclockwise

# Given three collinear points p, q, r, checks if point q lies on line segment 'pr'
func on_segment(p, q, r):
	return q.x <= max(p.x, r.x) and q.x >= min(p.x, r.x) and q.y <= max(p.y, r.y) and q.y >= min(p.y, r.y)

