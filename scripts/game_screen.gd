extends Node

# Assume player identifiers are 0 and 1 for simplicity
var current_player:int = 0 	# 0 is black, 1 is white
var moves_left:int = 20 # 10 moves for each player
var player_scores:Array[float] = [150, 0]

# Ugh, didn't bring GameScreen idea over. So now there's more state...
var game_over:bool

@onready var camera = $Camera
@export var game_board:GameBoard
@export var game_over_screen:GameOverScreen
#@export var scoreDisplay:ScoreDisplay
#@export var turnIndicator:TurnIndicator
#@export var gameOverScreen:GameOverScreen

@export var debug_score_display:ScoreDisplay

func _ready():
	reset_game()
	update_ui()
	
func _process(delta):
	
	handle_input()
	
func handle_input():
	
	if game_over:
		return
	
	var mouse_world_position = debug_score_display.get_canvas_transform().affine_inverse() \
									* get_viewport().get_mouse_position()
	var add_randomness = true		
	debug_score_display.update_mouse(mouse_world_position)
	
	if add_randomness:
		mouse_world_position += Vector2(randi() % 42 - 20, randi() % 42 - 20)
									
	var on_circle = mouse_world_position.distance_to(Vector2.ZERO) < 256	
	
	if (Input.is_action_just_pressed("Confirm") and on_circle):
		add_point_to_board(mouse_world_position)
	

func reset_game():
	current_player = 0
	moves_left = 20
	player_scores = [150.0, 0.0]
	
	game_over = false
	if game_over_screen.visible:
		game_over_screen.visible = false

	# Reset the game board 
	game_board.reset_board()
	#gameOverScreen.hide()
	update_ui()

func update_ui():
	debug_score_display.update_scores(player_scores, moves_left, current_player)
	pass

func switch_turns():
	current_player = 1 - current_player # Switches between 0 and 1
	moves_left -= 1
	update_ui()
	check_for_game_over()

func check_for_game_over():
	if moves_left <= 0:
		end_game()

func end_game():
	var winner = 0 if player_scores[0] > player_scores[1] else 1
	game_over = true
	
	
func add_point_to_board(point_position):
	if game_board.add_point(current_player, point_position):
		update_ui()
		switch_turns()
	pass

func _on_territory_count_triangle(triangle:Delaunay.Triangle, player:int):
	var a = triangle.edge_ab.length()
	var b = triangle.edge_bc.length()
	var c = triangle.edge_ca.length()
	var first = a + b + c
	var second = -a + b + c
	var third = a - b + c
	var fourth = a + b - c
	var area = sqrt(first * second * third * fourth) / 4
	player_scores[player] += area
	
	update_ui()



func _on_territory_finished_scoring():
	if game_over && not game_over_screen.visible:
		game_over_screen.set_scores(player_scores[0], player_scores[1])
		game_over_screen.visible = true
		

func _on_restart_button_pressed():
	reset_game()
