extends Control
class_name NegotiateColorsScreen

@onready var color_selection = $"MarginContainer/Color Selection"
@onready var color_bidding = $"MarginContainer/Color Bidding"

@onready var selection_player_1_label = $"MarginContainer/Color Selection/Player 1 Label"
@onready var selection_player_2_label = $"MarginContainer/Color Selection/Player 2 Label"
@onready var selection_play_black_button:Button = $"MarginContainer/Color Selection/HBoxContainer/Play Black"
@onready var selection_play_white_button:Button = $"MarginContainer/Color Selection/HBoxContainer/Play White"
@onready var selection_exit_button = $"MarginContainer/Color Selection/Exit Button"
@onready var selection_choosing_label = $"MarginContainer/Color Selection/Choosing Label"
@onready var selection_waiting_label = $"MarginContainer/Color Selection/Waiting Label"

@onready var bidding_player_label = $"MarginContainer/Color Bidding/Player Label"
@onready var bidding_explanation_label = $"MarginContainer/Color Bidding/Bid Explanation"
@onready var bidding_bid_amount = $"MarginContainer/Color Bidding/HBoxContainer3/HBoxContainer/Bid Amount"
@onready var bidding_waiting_label = $"MarginContainer/Color Bidding/HBoxContainer3/Waiting Label"
@onready var bidding_bid_button = $"MarginContainer/Color Bidding/HBoxContainer2/Bid Button"
@onready var bidding_exit_button = $"MarginContainer/Color Bidding/HBoxContainer2/Exit Button"

var local_player_one_chose_bid:bool
var local_player_one_chose_color:bool
var local_player_one_chose_black:bool
var local_player_two_chose_black:bool

signal finished_choosing_colors
signal play_click

func _ready():
	color_selection.visible = true
	color_bidding.visible = false
	selection_waiting_label.text = ""
	local_player_one_chose_color = false
	$"/root/Lobby".update_color_choices.connect(_on_update_color_choices)
	$"/root/Lobby".ready_to_bid.connect(_on_ready_to_bid)
	
	selection_player_1_label.text = $"/root/Lobby".players[1].name
	selection_player_2_label.text = $"/root/Lobby".players[$"/root/Lobby".guest_player_id].name
		
	if $"/root/Lobby".players[1].online:
		selection_choosing_label.text = "Choose a Color"
	else:
		selection_choosing_label.text = "Player 1: Choose a Color"
	
func _on_select_black_button_pressed():
	play_click.emit()
	if $"/root/Lobby".players[1].online:
		select_online(true)
	else:
		select_local(true)	
	
func _on_select_white_button_pressed():
	play_click.emit()
	if $"/root/Lobby".players[1].online:
		select_online(false)
	else:
		select_local(false)	
		
func select_local(chose_black:bool):
	var lobby:Lobby = get_node("/root/Lobby")
	if not local_player_one_chose_color:
		local_player_one_chose_color = true
		local_player_one_chose_black = chose_black
		print("local game, player 1 chose " + ("BLACK" if chose_black else "WHITE"))
		lobby.players[1].color_choice = 0 if chose_black else 1
		var align = HORIZONTAL_ALIGNMENT_LEFT if chose_black else HORIZONTAL_ALIGNMENT_RIGHT
		selection_player_1_label.horizontal_alignment = align
		selection_choosing_label.text = "Player 2: Choose a Color"
		
		if lobby.players[1].single_player:
			finished_choosing_colors.emit()
			
	else:
		local_player_two_chose_black = chose_black
		print("local game, player 2 chose " + ("BLACK" if chose_black else "WHITE"))
		lobby.players[2].color_choice = 0 if chose_black else 1
		var align = HORIZONTAL_ALIGNMENT_LEFT if chose_black else HORIZONTAL_ALIGNMENT_RIGHT
		selection_player_2_label.horizontal_alignment = align
		if lobby.players[1].color_choice != lobby.players[2].color_choice:
			finished_choosing_colors.emit()
		else:
			_on_ready_to_bid()
		
#		print("local game, player 2 bid: " + bidding_bid_amount.text)
#		# more logic for bid resolving? or kick off til later
#		lobby.players[2].black_bid = int(bidding_bid_amount.text)
#		finished_choosing_colors.emit()

func _on_ready_to_bid():
	$"/root/Lobby".print(" _on_ready_to_bid()")
	color_selection.visible = false
	set_bidding_text()
	color_bidding.visible = true
				
	
func select_online(chose_black:bool):
	var lobby:Lobby = get_node("/root/Lobby")
	var id = str(lobby.multiplayer.get_unique_id())
	lobby.players[int(id)].color_choice = 0 if chose_black else 1
	lobby.player_chose_color.rpc(int(id), lobby.players[int(id)].color_choice) 

	selection_play_black_button.disabled = true
	selection_play_white_button.disabled = true

	var other_player_name:String
	if int(id) == 1:
		other_player_name = lobby.players[lobby.guest_player_id].name
	else:
		other_player_name = lobby.players[1].name
	selection_waiting_label.visible = true
	selection_waiting_label.text = "Waiting for " + other_player_name
	
func _on_update_color_choices():
	var lobby:Lobby = get_node("/root/Lobby")
	if lobby.players[1].color_choice == -1:
		selection_player_1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif lobby.players[1].color_choice == 0:
		selection_player_1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	elif lobby.players[1].color_choice == 1:
		selection_player_1_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		
	if lobby.players[lobby.guest_player_id].color_choice == -1:
		selection_player_2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif lobby.players[lobby.guest_player_id].color_choice == 0:
		selection_player_2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	elif lobby.players[lobby.guest_player_id].color_choice == 1:
		selection_player_2_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
func set_bidding_text():
	var wanted_color = "BLACK" if $"/root/Lobby".players[1].color_choice == 0 else "WHITE"
	var other_color = "BLACK" if $"/root/Lobby".players[1].color_choice == 1 else "WHITE"
	
	bidding_explanation_label.text = "Both players want to play as " + wanted_color + ".\n\n" \
		+ "How much is playing as " + wanted_color + " worth?\nThe player with the highest bid" \
		+ " will \nplay as " + wanted_color + ". The other player will \nplay as " + other_color \
		+ " and get that bid as \nbonus points."
		
func _on_bid_button_pressed():
	play_click.emit()
	print("Bid button pressed")
	
	if $"/root/Lobby".players[1].online:
		bid_online()
		bidding_bid_button.disabled = true
	else:
		bid_local()	
		
func bid_online():
	var lobby:Lobby = get_node("/root/Lobby")
	var id = str(lobby.multiplayer.get_unique_id())
	print("unique id is " + str(id))
	print("online game, player " + str(id) + " bid: " + bidding_bid_amount.text)
	lobby.players[int(id)].color_bid = int(bidding_bid_amount.text)
	lobby.player_bid.rpc(int(id), lobby.players[int(id)].color_bid) 

	var other_player_name:String
	if int(id) == 1:
		other_player_name = lobby.players[lobby.guest_player_id].name
	else:
		other_player_name = lobby.players[1].name
	bidding_waiting_label.visible = true
	bidding_waiting_label.text = "Waiting for " + other_player_name
		
func bid_local():
	var lobby:Lobby = get_node("/root/Lobby")
	if not local_player_one_chose_bid:
		print("local game, player 1 bid: " + bidding_bid_amount.text)
		local_player_one_chose_bid = true
		lobby.players[1].color_bid = int(bidding_bid_amount.text)
		bidding_bid_amount.text = "0"
		bidding_player_label.text = "Player 2"
	else:
		print("local game, player 2 bid: " + bidding_bid_amount.text)
		# more logic for bid resolving? or kick off til later
		lobby.players[2].color_bid = int(bidding_bid_amount.text)
		finished_choosing_colors.emit()


func _on_exit_button_pressed():
	play_click.emit()
	print("Exit button pressed")
	# disconnect if a multiplayer game
	# quit to menu scene
#	get_tree().change_scene_to_file("res://scenes/main.tscn")
	pass # Replace with function body.
