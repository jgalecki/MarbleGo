extends Control

@onready var player_1_label = $"PanelContainer/MarginContainer/VBoxContainer/Player 1 Label"
@onready var player_2_label = $"PanelContainer/MarginContainer/VBoxContainer/Player 2 Label"


# Called when the node enters the scene tree for the first time.
func init():
	var lobby:Lobby = get_node("/root/Lobby")
	var p2_id = lobby.guest_player_id
	
	if lobby.players[1].single_player:
		lobby.players[1].color = lobby.players[1].color_choice
		lobby.players[p2_id].color = 1 - lobby.players[1].color_choice
		player_1_label.text = "Player 1: " + ("BLACK" if lobby.players[1].color == 0 else "WHITE")
		player_2_label.text = "Player 2: " + ("BLACK" if lobby.players[p2_id].color == 0 else "WHITE")

		lobby.players[1].color_bid = 0
		lobby.players[p2_id].color_bid = 0
		
		lobby.player_loaded()
		lobby.player_loaded()
		return
	
	# players want different colors
	if lobby.players[1].color_choice != lobby.players[p2_id].color_choice:
		lobby.players[1].color_bid = 0
		lobby.players[p2_id].color_bid = 0
		
		lobby.players[1].color = lobby.players[1].color_choice
		lobby.players[p2_id].color = lobby.players[p2_id].color_choice
	# players want the same colors
	else:
		$"/root/Lobby".print("Conflicting color choices. Bids: " + str(lobby.players[1].color_bid) + ", guest " + str(lobby.players[p2_id].color_bid))
		if lobby.players[1].color_bid >= lobby.players[p2_id].color_bid:
			lobby.players[1].color = lobby.players[1].color_choice
			lobby.players[p2_id].color = 1 - lobby.players[1].color_choice
			lobby.players[p2_id].color_bid = 0
		else:
			lobby.players[1].color = 1 - lobby.players[p2_id].color_choice
			lobby.players[p2_id].color = lobby.players[p2_id].color_choice
			lobby.players[1].color_bid = 0
	
	if lobby.players[1].online:
		player_1_label.text = lobby.players[1].name + ": " + ("BLACK" if lobby.players[1].color == 0 else "WHITE")
		player_2_label.text = lobby.players[p2_id].name + ": " + ("BLACK" if lobby.players[p2_id].color == 0 else "WHITE")
	else:
		player_1_label.text = "Player 1: " + ("BLACK" if lobby.players[1].color == 0 else "WHITE")
		player_2_label.text = "Player 2: " + ("BLACK" if lobby.players[p2_id].color == 0 else "WHITE")

	if lobby.players[1].online:
		lobby.player_loaded.rpc()	
	else:
		lobby.player_loaded()
		lobby.player_loaded()
	
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_player_assignment_button_pressed():
	$"/root/Lobby".print("players acknowledged")
	self.visible = false
