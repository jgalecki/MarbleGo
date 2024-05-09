extends Node

@onready var local_options:VBoxContainer = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Local"
@onready var online_options:VBoxContainer = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online"
@onready var ai_options:VBoxContainer = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/AI"

@onready var rules_screen = $"CanvasLayer/Rules Screen"
@onready var credits_screen = $"CanvasLayer/Credits Screen"


@onready var waiting_for_guest = $"CanvasLayer/Waiting For Guest"
@onready var host_button = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online/GridContainer/Host Button"
@onready var join_button = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online/GridContainer/Join Button"

@onready var port_text:TextEdit = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online/GridContainer/Port Textbox"
@onready var ip_text:TextEdit = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online/GridContainer/IP Textbox"
@onready var name_text:TextEdit = $"CanvasLayer/Menu Options/MarginContainer/HBoxContainer/Online/GridContainer/Name Textbox"

# Called when the node enters the scene tree for the first time.
func _ready():
	online_options.visible = false
	local_options.visible = false
	ai_options.visible = false
	waiting_for_guest.visible = false
	rules_screen.visible = false
	credits_screen.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_local_pressed():
	online_options.visible = false
	local_options.visible = true
	ai_options.visible = false
	rules_screen.visible = false
	credits_screen.visible = false


func _on_online_pressed():
	online_options.visible = true
	local_options.visible = false
	ai_options.visible = false
	rules_screen.visible = false
	credits_screen.visible = false


func _on_rules_pressed():
	online_options.visible = false
	local_options.visible = false
	ai_options.visible = false
	rules_screen.visible = true
	credits_screen.visible = false


func _on_credits_pressed():
	online_options.visible = false
	local_options.visible = false
	ai_options.visible = false
	rules_screen.visible = false
	credits_screen.visible = true


func _on_exit_pressed():
	pass


func _on_host_button_pressed():
	if name_text.text == "":
		return
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.player_info.name = name_text.text
	lobby.player_info.online = true
	var error = lobby.create_game(int(port_text.text))
	if error:
		lobby.print(error)
	waiting_for_guest.visible = true
	lobby.ready_to_pick.connect(_on_ready_to_pick)
#
#	var ips = IP.get_local_addresses()
#
#	ip_text.text = str(ips[0]) + " (???)"
	
func _on_join_button_pressed():
	if name_text.text == "":
		return
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.player_info.name = name_text.text
	lobby.player_info.online = true
	var error = lobby.join_game(ip_text.text, int(port_text.text))
	if error:
		lobby.print(error)
	lobby.ready_to_pick.connect(_on_ready_to_pick)
	
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
	ai_options.visible = true

func _on_play_two_player_local_pressed():
	ai_options.visible = false
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.players[1] = { "name": "Player 1", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": false }
	lobby.players[2] = { "name": "Player 2", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": false }
	lobby.guest_player_id = 2
	lobby.load_game("res://scenes/main.tscn")
#	negotiate_colors.visible = true
#	local_two_player_bid_count = 0
#	negotiate_colors_bid_textedit.text = "0"


func _on_ready_to_pick():
	waiting_for_guest.visible = false
#	negotiate_colors.visible = true
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.load_game("res://scenes/main.tscn")
	


func _on_rules_return_button_pressed():
	rules_screen.visible = false
	credits_screen.visible = false
	online_options.visible = false
	local_options.visible = false
	waiting_for_guest.visible = false


func _on_moonroof_button_pressed():
#	sound_player.play_confirm()
	OS.shell_open("https://joshuagalecki.itch.io/") 

func _on_discord_button_pressed():
#	sound_player.play_confirm()
	OS.shell_open("https://discord.gg/dg4GeeupQW") 


func _on_github_button_pressed():
	OS.shell_open("https://github.com/jgalecki/MarbleGo") 


func _on_online_name_changed():
	if name_text.text == "":
		host_button.disabled = true
		join_button.disabled = true
	else:
		host_button.disabled = false
		join_button.disabled = false
		


func _on_random_randy_ai_button_pressed():
	# Later, if needed, we'll need to name our players and choose the AI here...
	var lobby:Lobby = get_node("/root/Lobby")
	lobby.players[1] = { "name": "Player 1", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": true }
	lobby.players[2] = { "name": "Random Randy", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": true }
	lobby.guest_player_id = 2
	lobby.load_game("res://scenes/main.tscn")


func playClick():
	pass # Replace with function body.
