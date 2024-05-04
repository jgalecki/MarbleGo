extends Node

@onready var local_options:VBoxContainer = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Local"
@onready var online_options:VBoxContainer = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online"
@onready var rules_screen = $"CanvasLayer/Rules Screen"


@onready var waiting_for_guest = $"CanvasLayer/Waiting For Guest"


@onready var ip_text:TextEdit = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online/IP Textbox"
@onready var name_text:TextEdit = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online/Name Textbox"

# Called when the node enters the scene tree for the first time.
func _ready():
	online_options.visible = false
	local_options.visible = false
	waiting_for_guest.visible = false
	rules_screen.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_local_pressed():
	online_options.visible = false
	local_options.visible = true


func _on_online_pressed():
	online_options.visible = true
	local_options.visible = false


func _on_rules_pressed():
	online_options.visible = false
	local_options.visible = false
	rules_screen.visible = true


func _on_credits_pressed():
	online_options.visible = false
	local_options.visible = false


func _on_exit_pressed():
	pass


func _on_host_button_pressed():
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.player_info.name = name_text.text
	lobby.player_info.online = true
	lobby.create_game()
	waiting_for_guest.visible = true
	lobby.ready_to_bid.connect(_on_ready_to_bid)
	
	var ips = get_local_ips("192.168")
	if ips.size() == 0:
		ips = IP.get_local_addresses()
		
	ip_text.text = str(ips[0]) + " (???)"
	
	
#	print("Creating a server on port " + port_text.text)
#
#	peer.create_server(int(port_text.text))
#	var first_home_ip = get_local_ips("192.168")[0]
#	ip_text.text = str(first_home_ip) + " (???)"
#	for ip in IP.get_local_addresses():
#		print("IP address is " + ip)
#	ip_text.editable = false
#	multiplayer.multiplayer_peer = peer
#	multiplayer.peer_connected.connect(_add_player)
#	_add_player()
#
#func _add_player(id = 11):
#	print("Player added, id " + str(id))

func _on_join_button_pressed():
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.player_info.name = "guest"
	lobby.player_info.online = true
	lobby.join_game(ip_text.text)
	lobby.ready_to_bid.connect(_on_ready_to_bid)
	
	# Show Waiting dialog

func get_local_ips(starts_with:String):
	var all_ips = IP.get_local_addresses()  # This retrieves all local IP addresses
	var filtered_ips = PackedStringArray()  # Initialize an empty PackedStringArray for the filtered results

	# Loop through all IP addresses and add those that start with "192.168" to the filtered_ips array
	for ip in all_ips:
		if ip.begins_with(starts_with):
			filtered_ips.append(ip)

	return filtered_ips


func _on_play_one_player_local_pressed():
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.players[1] = { "name": "Player 1", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": true }
	lobby.players[2] = { "name": "Player 2", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": true }
	lobby.guest_player_id = 2
	lobby.load_game("res://scenes/main.tscn")

func _on_play_two_player_local_pressed():
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.players[1] = { "name": "Player 1", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": false }
	lobby.players[2] = { "name": "Player 2", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": false }
	lobby.guest_player_id = 2
	lobby.load_game("res://scenes/main.tscn")
#	negotiate_colors.visible = true
#	local_two_player_bid_count = 0
#	negotiate_colors_bid_textedit.text = "0"


func _on_ready_to_bid():
	waiting_for_guest.visible = false
#	negotiate_colors.visible = true
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.load_game("res://scenes/main.tscn")
	


func _on_rules_return_button_pressed():
	rules_screen.visible = false

