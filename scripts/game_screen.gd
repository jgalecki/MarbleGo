extends Node

@onready var player_assignment_screen = $"CanvasLayer/Player Assignment Screen"
@onready var negotiate_colors = $"CanvasLayer/Negotiate Colors"

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

@export var debug_score_display:ScoreDisplay
var explode_particle_prefab = preload("res://prefab_scenes/explode_particles.tscn")

var white_bonus:int
var black_bonus:int

var ai:Ai

var switch_turns_count:int

func _ready():
#	reset_game()
	update_ui()
	
func _process(delta):	
	if player_assignment_screen.visible || negotiate_colors.visible:
		return
#	print("Past start hold")
	
	handle_input()
	
func handle_input():
	
	if game_over:
		return
	
	var lobby = $"/root/Lobby"
	var has_control = not lobby.players[1].online || lobby.player_info.color == current_player
	var has_remote_control = lobby.players[1].online \
							 && lobby.player_info.color != lobby.players[1].color \
							 && lobby.player_info.color == current_player
	
	var mouse_world_position = get_viewport().get_mouse_position() - get_viewport().get_visible_rect().get_center()
#
#	print(str(mouse_world_position) + ", " + str(mouse_world_position_2))
#
	if is_shooting:
		if not has_control:
			return
		if has_remote_control:
			remote_control_shooting.rpc(mouse_world_position, Input.is_action_just_released("Confirm"))
			
			var aiming_delta = (game_board.shooting_marble.position * camera.zoom.x) \
								 - mouse_world_position
			
			# if no mouse movement, aim towards the origin / center of the board
			if aiming_delta.length() == 0:
				aiming_delta = game_board.shooting_marble.position * -1
						
			shooting_arrow.position = game_board.shooting_marble.position \
									- aiming_delta.normalized() * 45
			shooting_arrow.rotation = aiming_delta.angle()
			var shooting_strength = minf(1, aiming_delta.length() / 100.0)
			shooting_arrow.scale.y = shooting_strength
			if shooting_strength >= 0.98:
				shooting_arrow.modulate = Color(0.776, 0.623, 0.647)
				shooting_arrow.scale.x = 2
			else:
				shooting_arrow.modulate = Color(1, 1, 1)
				shooting_arrow.scale.x = 1
		else:
			
			if lobby.players[1].single_player && lobby.players[1].color != current_player:
				# AI shooting
				var shooting_strength = ai.shoot_marble_power()
				if shooting_strength >= 0.98:
					shooting_strength *= 2
				var aiming_delta = Vector2(1, 0).rotated(ai.shoot_marble_angle())
				game_board.shoot(aiming_delta.normalized(), 500 * shooting_strength)
				
				switch_to_rolling_phase.rpc()
				
			# update ui for arrow or something?
			debug_score_display.update_mouse(1, mouse_world_position)
			
			var aiming_delta = (game_board.shooting_marble.position * camera.zoom.x) \
								 - mouse_world_position
			# if no mouse movement, aim towards the origin / center of the board
			if aiming_delta.length() == 0:
				aiming_delta = game_board.shooting_marble.position * -1
						
			shooting_arrow.position = game_board.shooting_marble.position \
									+ aiming_delta.normalized() * 45
			shooting_arrow.rotation = aiming_delta.angle()
			var shooting_strength = min(1, aiming_delta.length() / 100.0)
			shooting_arrow.scale.y = shooting_strength
			if shooting_strength >= 0.98:
				shooting_arrow.modulate = Color(0.776, 0.623, 0.647)
				shooting_arrow.scale.x = 2
			else:
				shooting_arrow.modulate = Color(1, 1, 1)
				shooting_arrow.scale.x = 1
			
			if Input.is_action_just_released("Confirm"):
				if shooting_strength >= 0.98:
					shooting_strength *= 2
				game_board.shoot(aiming_delta.normalized(), 500 * shooting_strength)
				switch_to_rolling_phase.rpc()
			
	elif is_placing:
		if not has_control:
			return
		if has_remote_control:
			remote_control_placement.rpc(mouse_world_position, Input.is_action_just_pressed("Confirm"))
			
			var near_board = 350 * camera.zoom.x
			if game_board.position.distance_to(mouse_world_position) <= near_board \
				&& Input.is_action_just_pressed("Confirm"):
				shooting_arrow.position = game_board.shooting_marble.position
				shooting_arrow.visible = true
				
		else:
			if lobby.players[1].single_player && lobby.players[1].color != current_player:
				# AI placement
				game_board.shooting_marble.position = ai.place_marble(game_board.black_marbles, game_board.white_marbles, game_board.border_marbles)
				switch_to_shooting_phase.rpc()
			
			var near_board = 350 * camera.zoom.x
			if game_board.position.distance_to(mouse_world_position) > near_board:
				game_board.shooting_marble.visible = false
				debug_score_display.update_mouse(0, camera.position)
				return
			else:
				game_board.shooting_marble.visible = true


			var perimeter_position = mouse_world_position.normalized() * 256
			debug_score_display.update_mouse(0, perimeter_position)
			game_board.move_shot_around_perimeter(perimeter_position)

			if Input.is_action_just_pressed("Confirm"):
				switch_to_shooting_phase.rpc()
				shooting_arrow.position = game_board.shooting_marble.position
				shooting_arrow.visible = true
			
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
			print($"/root/Lobby".own_name() + ": "+ player + " is done with their turn.")
			
			
			update_borders()
			capture_marbles()
			player_scores = [black_bonus, white_bonus]
			game_board.start_territory_count()
	else:
		debug_score_display.update_mouse(3, mouse_world_position)
		
@rpc("any_peer", "call_remote", "reliable")
func remote_control_placement(mouse_pos:Vector2, clicked:bool):
	var near_board = 350 * camera.zoom.x
	if game_board.position.distance_to(mouse_pos) > near_board:
		game_board.shooting_marble.visible = false
		debug_score_display.update_mouse(0, camera.position)
		return
	else:
		game_board.shooting_marble.visible = true
		
	
	var perimeter_position = mouse_pos.normalized() * 256
	debug_score_display.update_mouse(0, perimeter_position)
	game_board.move_shot_around_perimeter(perimeter_position)

	if clicked:
		switch_to_shooting_phase.rpc()
		shooting_arrow.position = game_board.shooting_marble.position
		shooting_arrow.visible = true
	
@rpc("any_peer", "call_remote", "reliable")
func remote_control_shooting(mouse_pos:Vector2, released:bool):
	# update ui for arrow or something?
	debug_score_display.update_mouse(1, mouse_pos)
	
	var aiming_delta = (game_board.shooting_marble.position * camera.zoom.x) - mouse_pos
	# if no mouse movement, aim towards the origin / center of the board
	if aiming_delta.length() == 0:
		aiming_delta = game_board.shooting_marble.position * -1
		
	shooting_arrow.position = game_board.shooting_marble.position \
							- aiming_delta.normalized() * 45
	shooting_arrow.rotation = aiming_delta.angle()
	var shooting_strength = minf(1, aiming_delta.length() / 100.0)
	shooting_arrow.scale.y = shooting_strength
	if shooting_strength >= 0.98:
		shooting_arrow.modulate = Color(0.776, 0.623, 0.647)
		shooting_arrow.scale.x = 2
	else:
		shooting_arrow.modulate = Color(1, 1, 1)
		shooting_arrow.scale.x = 1
	
	if released:
		shooting_arrow.scale.y = shooting_strength
		if shooting_strength >= 0.98:
			shooting_strength *= 2
		game_board.shoot(aiming_delta.normalized(), 500 * shooting_strength)
		switch_to_rolling_phase.rpc()

@rpc("any_peer", "call_local", "reliable")
func switch_to_shooting_phase():
	is_placing = false
	is_shooting = true
	var player = "BLACK" if current_player == 0 else "WHITE"
	$"/root/Lobby".print(player + " is now shooting.")
	
#	shooting_arrow.position = game_board.shooting_marble.position
	game_board.shooting_marble.camera = camera
	
@rpc("any_peer", "call_local", "reliable")
func switch_to_rolling_phase():
	shooting_arrow.visible = false
	
	# nothing for power / distance yet. 
	is_shooting = false
	is_rolling = true		
	var player = "BLACK" if current_player == 0 else "WHITE"
	$"/root/Lobby".print(player + " is now rolling.")
	

func reset_game():
	current_player = 0
	current_turn = 0
	switch_turns_count = 0
	
	var lobby:Lobby = get_node("/root/Lobby")
	if lobby.players[1].color_bid > 0:
		if lobby.players[1].color == 0:
			white_bonus = lobby.players[1].color_bid
			black_bonus = 0
		else:
			black_bonus = lobby.players[1].color_bid
			white_bonus = 0
	elif lobby.players[lobby.guest_player_id].color_bid > 0:
		if lobby.players[lobby.guest_player_id].color == 0:
			white_bonus = lobby.players[lobby.guest_player_id].color_bid
			black_bonus = 0
		else:
			black_bonus = lobby.players[lobby.guest_player_id].color_bid
			white_bonus = 0
	else:
			white_bonus = 0
			black_bonus = 0

			
	if lobby.players[1].single_player:
		ai = AI_Random_Randy.new()
		if lobby.players[1].color == 0:
			white_bonus = ai.ai_handicap() * 100
		else:
			black_bonus = ai.ai_handicap() * 100
	else:
		ai = null
		
		
#	$"/root/Lobby".print("Bids2: host " + str(lobby.players[1].color_bid) + ", guest " + str(lobby.players[lobby.guest_player_id].color_bid))
#	if lobby.players[1].color_bid >= lobby.players[lobby.guest_player_id].color_bid:
#		white_bonus = lobby.players[1].color_bid * 100
#	else:
#		white_bonus = lobby.players[lobby.guest_player_id].color_bid * 100
#
	lobby.print("black_bonus is " + str(black_bonus) + ", white_bonus is " + str(white_bonus))
	player_scores = [black_bonus, white_bonus]
	
	game_over = false
	if game_over_screen.visible:
		game_over_screen.visible = false

	# Reset the game board 
	game_board.reset_board()
	#gameOverScreen.hide()
	is_placing = true
	
	if lobby.multiplayer.is_server():
		game_board.init_next_marble(current_player)
	for border_marble in game_board.border_marbles:
		border_marble.camera = camera
	
	update_ui()

func update_ui():
	debug_score_display.update_scores(player_scores, current_turn, current_player)
	pass


@rpc("any_peer", "call_local", "reliable")
func switch_turns():
	if $"/root/Lobby".players[1].online:
		switch_turns_online()
		
	else:
		switch_turns_local()

@rpc("authority", "call_local", "reliable")
func switch_turns_local():
	current_player = 1 - current_player # Switches between 0 and 1
	current_turn += 1
	if current_player == 0:
		$"/root/Lobby".print("BLACK's turn " + str(current_turn))
	else:
		$"/root/Lobby".print("WHITE's turn " + str(current_turn))
	update_ui()

	next_turn()
	

func switch_turns_online():
	if $"/root/Lobby".multiplayer.is_server():
		print("Host got ready-for-turn-call")
		switch_turns_count += 1
		if switch_turns_count >= 2:
			print("Host is switching turns")
			switch_turns_count = 0
			switch_turns_local.rpc()
	
@rpc("authority", "call_local", "reliable")
func next_turn():
	if $"/root/Lobby".multiplayer.is_server():
		game_board.init_next_marble(current_player)
		
	for black_marble in game_board.black_marbles:
		black_marble.spawned_particles_this_turn = false
	for white_marble in game_board.white_marbles:
		white_marble.spawned_particles_this_turn = false
	
	is_placing = true

func end_game():
	game_over = true
	
	if not game_over_screen.visible:
		game_over_screen.set_scores(player_scores[0], player_scores[1])
		game_over_screen.visible = true
	

func _on_territory_count_triangle(tri:Territory.Tri):
	player_scores[tri.owner] += tri.area
	
	update_ui()



func _on_territory_finished_scoring():
	$"/root/Lobby".print("Finished counting territory")

	if current_turn >= check_for_end_turn:
		end_game()
			
	if game_over && not game_over_screen.visible:
		game_over_screen.set_scores(player_scores[0], player_scores[1])
		game_over_screen.visible = true
		
	if not game_over:
		game_board.update_marbles_after_turn()
		update_ui()
		switch_turns.rpc()
		

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
		switch_turns.rpc()
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
		
		
	calculate_marble_distances()	
	
	# go with the current player first
	if current_player == 0:
		capture_white_marbles()
		capture_black_marbles()
	else:
		capture_black_marbles()
		capture_white_marbles()
		
		
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
			particles.modulate = Color(0.984, 0.961, 0.937)
			hit_lag(0.5, 1)
			camera.shake(1000, 1)
	dead_marbles.reverse()
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
			particles.modulate = Color(0.153, 0.153, 0.267)
			particles.position = black.position
			hit_lag(0.5, 1)
			camera.shake(1000, 1)
	dead_marbles.reverse()
	for i in dead_marbles:
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


func _on_player_assignment_button_pressed():
	pass # Replace with function body.

# Called when all players have loaded the game scene
@rpc("authority", "call_local", "reliable")
func start_game():
	print("start_game() called! Let's go!")
	reset_game()
	
@rpc("any_peer", "call_local", "reliable")
func show_player_colors():
	negotiate_colors.visible = false
	player_assignment_screen.init()
	player_assignment_screen.visible = true
