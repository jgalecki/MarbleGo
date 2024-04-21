extends Node

var current_player:int = 0 	# 0 is black, 1 is white
var current_turn:int = 0
var check_for_end_turn:int = 41
var player_scores:Array[float] = [0, 0]

# Ugh, didn't bring GameScreen idea over. So now there's more state...
var game_over:bool
var is_placing:bool
var is_shooting:bool
var is_rolling:bool

@onready var camera = $Camera
@export var game_board:GameBoard
@export var game_over_screen:GameOverScreen
@export var shooting_arrow:Sprite2D
@export var shooting_fill:Sprite2D
var shooting_timer:float
var shooting_strength:float

@export var debug_score_display:ScoreDisplay
var explode_particle_prefab = preload("res://prefab_scenes/explode_particles.tscn")

func _ready():
	reset_game()
	update_ui()
	
func _process(delta):	
	
	if is_shooting:
		shooting_timer += delta
		if shooting_timer > 1.5:
			shooting_timer = 0
		
#		if shooting_timer < 0.6:
#			shooting_strength = shooting_timer / 2.0
#		elif shooting_timer < 0.8:
#			shooting_strength = 0.3 + (shooting_timer - 0.6)
#		elif shooting_timer < 0.95:
#			shooting_strength = 0.5 + (shooting_timer - 0.8) * 2
#		else:
#			shooting_strength = 0.8 + (shooting_timer - 0.95) * 4
		if shooting_timer <= 0.75:
			shooting_strength = shooting_timer
		else:
			shooting_strength = 1.5 - shooting_timer
			
		shooting_fill.scale.x = shooting_strength
	
	handle_input()
	
func handle_input():
	
	if game_over:
		return
	
	var mouse_world_position = debug_score_display.get_canvas_transform().affine_inverse() \
									* get_viewport().get_mouse_position()
			
	if is_shooting:
		# update ui for arrow or something?
		debug_score_display.update_mouse(1, mouse_world_position)
		
		var aiming_delta = game_board.shooting_marble.position - mouse_world_position
		# if no mouse movement, aim towards the origin / center of the board
		if aiming_delta.length() == 0:
			aiming_delta = game_board.shooting_marble.position * -1
					
		shooting_arrow.position = game_board.shooting_marble.position \
								- aiming_delta.normalized() * 45
		shooting_arrow.rotation = aiming_delta.angle()
		
		if Input.is_action_just_pressed("Confirm"):
			shooting_arrow.visible = false
			
			# nothing for power / distance yet. 
			game_board.shoot(aiming_delta.normalized(), 1000 * shooting_strength)
			is_shooting = false
			is_rolling = true		
			var player = "BLACK" if current_player == 0 else "WHITE"
			print(player + " is now rolling.")
		
	elif is_placing:
		if mouse_world_position.length() > 300:
			game_board.shooting_marble.visible = false
			return
		else:
			game_board.shooting_marble.visible = true
			
		
		var perimeter_position = mouse_world_position.normalized() * 256
		debug_score_display.update_mouse(0, perimeter_position)
		game_board.move_shot_around_perimeter(perimeter_position)
	
		if Input.is_action_just_pressed("Confirm"):
			is_placing = false
			is_shooting = true
			var player = "BLACK" if current_player == 0 else "WHITE"
			print(player + " is now shooting.")
			
			shooting_arrow.visible = true
			shooting_arrow.position = game_board.shooting_marble.position
			shooting_timer = 0
			game_board.shooting_marble.camera = camera
			
	elif is_rolling:
		debug_score_display.update_mouse(2, mouse_world_position)
		var all_done_rolling = true
		for black_marble in game_board.black_marbles:
			if not black_marble.sleeping && not black_marble.border_marble:
				all_done_rolling = false
		for white_marble in game_board.white_marbles:
			if not white_marble.sleeping && not white_marble.border_marble:
				all_done_rolling = false
				
		if all_done_rolling:
			is_rolling = false
			game_board.shooting_marble.is_shooting = false
			game_board.shooting_marble.shadow.visible = true
			game_board.shooting_marble.trail_2d.visible = false
			var player = "BLACK" if current_player == 0 else "WHITE"
			print(player + " is done with their turn.")
			update_borders()
			capture_marbles()
			player_scores = [0, 0]
			game_board.start_territory_count()
	else:
		debug_score_display.update_mouse(3, mouse_world_position)

func reset_game():
	current_player = 0
	current_turn = 0
	player_scores = [0.0, 0.0]
	
	game_over = false
	if game_over_screen.visible:
		game_over_screen.visible = false

	# Reset the game board 
	game_board.reset_board()
	#gameOverScreen.hide()
	is_placing = true
	game_board.next_turn(current_player)
	for border_marble in game_board.border_marbles:
		border_marble.camera = camera
	
	update_ui()

func update_ui():
	debug_score_display.update_scores(player_scores, current_turn, current_player)
	pass

func switch_turns():
	current_player = 1 - current_player # Switches between 0 and 1
	current_turn += 1
	if current_player == 0:
		print("BLACK's turn " + str(current_turn))
	else:
		print("WHITE's turn " + str(current_turn))
	update_ui()

func end_game():
	game_over = true
	
	if not game_over_screen.visible:
		game_over_screen.set_scores(player_scores[0], player_scores[1])
		game_over_screen.visible = true
	

func _on_territory_count_triangle(tri:Territory.Tri):
	player_scores[tri.owner] += tri.area
	
	update_ui()



func _on_territory_finished_scoring():
	print("Finished counting territory")

	if current_turn >= check_for_end_turn:
		end_game()
			
	if game_over && not game_over_screen.visible:
		game_over_screen.set_scores(player_scores[0], player_scores[1])
		game_over_screen.visible = true
		
	if not game_over:
		game_board.update_marbles_after_turn()
		is_placing = true
		update_ui()
		switch_turns()
		game_board.next_turn(current_player)
			
		for black_marble in game_board.black_marbles:
			black_marble.spawned_particles_this_turn = false
		for white_marble in game_board.white_marbles:
			white_marble.spawned_particles_this_turn = false

func _on_restart_button_pressed():
	reset_game()


func _on_pass_button_pressed():
	if player_scores[current_player] < player_scores[1 - current_player]:
		end_game()
		
	elif is_placing || is_shooting:
		game_board.remove_unplaced_marble(current_player)
		is_placing = true
		is_shooting = false
		shooting_arrow.visible = false
		
		update_ui()
		switch_turns()
		game_board.next_turn(current_player)
	else: 
		pass	# Allow cancelling out of shooting?		
		
func update_borders():
	var all_marbles:Array[Marble] = []
	all_marbles.append_array(game_board.black_marbles)	
	all_marbles.append_array(game_board.white_marbles)
	for border in game_board.border_marbles:
		if border.stable: continue
		border.nearest_marbles = get_closest_marbles(border.position, 5)
		border.update_after_turn()
		if border.flag_to_claim:
			if border.player == 0:
				game_board.black_marbles.append(border)
			else:
				game_board.white_marbles.append(border)
		
func capture_marbles():
		
	if game_board.last_turn_marble == null:
		game_board.last_turn_marble == game_board.shooting_marble
		
	calculate_marble_distances()	
	
	# go with the current player first
	if current_player == 0:
		capture_white_marbles()
		capture_black_marbles()
	else:
		capture_black_marbles()
		capture_white_marbles()
		
	game_board.last_turn_marble == game_board.shooting_marble
		
func calculate_marble_distances():
	var all_marbles:Array[Marble] = []
	all_marbles.append_array(game_board.black_marbles)	
	all_marbles.append_array(game_board.white_marbles)
	for marble in all_marbles:
		if marble.stable: continue
		marble.nearest_marbles = get_closest_marbles(marble.position, 4)
		
func get_closest_marbles(position:Vector2, limit:int) -> Array[Marble]:
	var all_marbles:Array[Marble] = []
	all_marbles.append_array(game_board.black_marbles)	
	all_marbles.append_array(game_board.white_marbles)
	var nearest:Array[Marble] = []
	for other in all_marbles:
		if position == other.position: continue
		nearest.append(other)
	nearest.sort_custom(func(a,b): \
		return position.distance_to(a.position) < position.distance_to(b.position))
	return nearest.slice(0, limit)
		
func capture_white_marbles():
	var dead_marbles = []
	for i in range(game_board.white_marbles.size()):
		var white = game_board.white_marbles[i]
		if not white.stable \
		   && not white.nearest_marbles.any(func(m): return m == null || m.player == 1) \
		   && white.nearest_marbles.size() == 4:
			dead_marbles.append(i)
			var particles:GPUParticles2D = explode_particle_prefab.instantiate()
			get_tree().current_scene.add_child(particles)
			particles.position = white.position
			hit_lag(0.2, 1)
			camera.shake(1000, 1)
	for i in dead_marbles:
		var dead = game_board.white_marbles[i]
		game_board.white_marbles.remove_at(i)
		for child in dead.get_children():
			child.queue_free()
		dead.queue_free()
		
func capture_black_marbles():
	var dead_marbles = []
	for i in range(game_board.black_marbles.size()):
		var black = game_board.black_marbles[i]
		if not black.stable \
		   && not black.nearest_marbles.any(func(m): return m == null || m.player == 0) \
		   && black.nearest_marbles.size() == 4:
			dead_marbles.append(i)
			var particles:GPUParticles2D = explode_particle_prefab.instantiate()
			get_tree().current_scene.add_child(particles)
			particles.modulate = Color(0, 0, 0)
			particles.position = black.position
			hit_lag(0.2, 1)
			camera.shake(1000, 1)
	for i in dead_marbles:
		print("REMOVING black marble index " + str(i))
		var dead = game_board.black_marbles[i]
		game_board.black_marbles.remove_at(i)
		for child in dead.get_children():
			child.queue_free()
		dead.queue_free()


func hit_lag(scale, duration):
	if Engine.time_scale < scale:
		return
	Engine.time_scale = scale
	await get_tree().create_timer(scale * duration).timeout
	Engine.time_scale = 1
