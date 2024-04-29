extends Control

@onready var player_1_label = $"PanelContainer/MarginContainer/VBoxContainer/Player 1 Label"
@onready var player_2_label = $"PanelContainer/MarginContainer/VBoxContainer/Player 2 Label"


# Called when the node enters the scene tree for the first time.
func init():
	var lobby:Lobby = get_node("/root/Lobby")
	
	$"/root/Lobby".print("Bids: " + str(lobby.players[1].black_bid) + ", guest " + str(lobby.players[lobby.guest_player_id].black_bid))
	if lobby.players[1].black_bid >= lobby.players[lobby.guest_player_id].black_bid:
		lobby.players[1].color = 0
		lobby.players[lobby.guest_player_id].color = 1
	else:
		lobby.players[1].color = 1
		lobby.players[lobby.guest_player_id].color = 0
	
	if lobby.players[1].online:
		player_1_label.text = lobby.players[1].name + ": " + ("BLACK" if lobby.players[1].color == 0 else "WHITE")
		player_2_label.text = lobby.players[lobby.guest_player_id].name + ": " + ("BLACK" if lobby.players[lobby.guest_player_id].color == 0 else "WHITE")
	else:
		player_1_label.text = "Player 1: " + ("BLACK" if lobby.players[1].color == 0 else "WHITE")
		player_2_label.text = "Player 2: " + ("BLACK" if lobby.players[lobby.guest_player_id].color == 0 else "WHITE")

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
