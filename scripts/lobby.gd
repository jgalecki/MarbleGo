extends Node
# Example from Godot website: https://docs.godotengine.org/en/stable/tutorials/networking/high_level_multiplayer.html
# Modified as needed

# Autoload named Lobby

# These signals can be connected to by a UI lobby scene or the game scene.
signal player_connected(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal ready_to_bid

const PORT = 7000
const DEFAULT_SERVER_IP = "127.0.0.1" # IPv4 localhost
const MAX_CONNECTIONS = 2

# This will contain player info for every player,
# with the keys being each player's unique IDs.
var players = {}

# This is the local player info. This should be modified locally
# before the connection is made. It will be passed to every other peer.
# For example, the value of "name" can be set to something the player
# entered in a UI scene.
var player_info = { "name": "Name", "color": -1, "score": 0, "color_choice": -1, "color_bid": 0, "online": false, "single_player": false }

var players_loaded = 0
var players_bid = 0
var players_color_chosen = 0

var guest_player_id:int = -1

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func join_game(address = ""):
	print("join_game() called")
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, PORT)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	guest_player_id = multiplayer.get_unique_id()
	print("join_game() successful with id " + str(guest_player_id))


func create_game():
	print("create_game() called")
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	print("create_game() successful")

	players[1] = player_info
	player_connected.emit(1, player_info)


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null


# When the server decides to start the game from a UI scene,
# do Lobby.load_game.rpc(filepath)
@rpc("call_local", "reliable")
func load_game(game_scene_path):
	print("load_game() called")
	get_tree().change_scene_to_file(game_scene_path)

# Every peer will call this when they have loaded the game scene.
@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	print("player_loaded() called on " + players[multiplayer.get_unique_id()].name)
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			print("starting game from player_loaded()")
			$/root/Main.start_game.rpc()
			players_loaded = 0

@rpc("any_peer", "call_local", "reliable")
func player_chose_color(id, color):
	print("player_chose_color() called")
	players[id].color_choice = color
	if multiplayer.is_server():
		players_color_chosen += 1
		if players_color_chosen == players.size():
			print("All players have chosen colors")
			players_color_chosen = 0
			# See if we need to go to bidding or if we can go to the game
#			$/root/Main.show_player_colors.rpc()
			
@rpc("any_peer", "call_local", "reliable")
func player_bid(id, bid):
	print("player_bid() called")
	players[id].color_bid = bid
	if multiplayer.is_server():
		players_bid += 1
		if players_bid == players.size():
			print("All players have bid")
			players_bid = 0
			$/root/Main.show_player_colors.rpc()

# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
func _on_player_connected(id):
	print("_on_player_connected() called, id " + str(id))
	_register_player.rpc_id(id, player_info)
	print("_on_player_connected() There are now " + str(players.size()) + " players")


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	print("_register_player() called")
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	if new_player_id != 1:
		guest_player_id = new_player_id
	player_connected.emit(new_player_id, new_player_info)
	print("_register_player() There are now " + str(players.size()) + " players")
	if players.size() == 2:
		ready_to_bid.emit()
		


func _on_player_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)


func _on_connected_ok():
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	
func own_name() -> String:
	return player_info.name
	
func own_color() -> int:
	return player_info.color

func print(message:String):
	print(player_info.name + ": " + message)
