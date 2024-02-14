extends Node

signal player_connected(peer_id, player_info)
signal player_1_info_updated(player_id, new_player_info,extra_index)
signal player_this_info_updated(player_id,new_player_info,extra_index)
signal player_disconnected(peer_id)
signal server_disconnected

const PORT = 6991
const DEFAULT_SERVER_IP = "127.0.0.1"
const MAX_CONNECTIONS = 20

@export var players: Dictionary = {}

var player_info = {"name": "Name", "cards": {0: "2", 1: "2", 2: "ACE"}}:
	set(value):
		player_info = value
		_update_player_info.rpc(player_info,player_1_info_updated,NAN)

var players_loaded = 0

var pre_deal_card_dict = {"1": {}, "2": {}}
var player_cards_1 = {}
var player_cards_2 = {}
var round_id = 1


func _ready():
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	pre_cards()
	deal_cards()


func join_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	if error:
		printerr(error)
		return
	multiplayer.multiplayer_peer = peer


func create_game():
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT, MAX_CONNECTIONS)
	if error:
		printerr(error)
		return
	multiplayer.multiplayer_peer = peer

	player_info["cards"] = player_cards_1
	players[1] = player_info
	player_connected.emit(1, player_info)
	change_round(1)


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null


@rpc("call_local", "reliable")
func load_game(game_scene_path):
	get_tree().change_scene_to_file(game_scene_path)


@rpc("any_peer", "call_local", "reliable")
func player_loaded():
	if multiplayer.is_server():
		players_loaded += 1
		if players_loaded == players.size():
			# $/root/Game.start_game()
			players_loaded = 0


@rpc("any_peer", "reliable")
func change_round(id):
	round_id = id
	print("Round: ", round_id)


func _on_peer_connected(id):
	if multiplayer.is_server():
		receive_return_data.rpc_id(id,player_cards_2,player_info)
	_register_player.rpc_id(id, player_info)


@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	var new_player_id = multiplayer.get_remote_sender_id()
	players[new_player_id] = new_player_info
	if multiplayer.is_server():
		new_player_info["cards"] = player_cards_2
		player_connected.emit(new_player_id, new_player_info)
	print(players)


@rpc("any_peer", "reliable", "call_remote")
func _update_player_info(new_player_info,which_signal,extra_index):
	var player_id = multiplayer.get_remote_sender_id()
	players[player_id] = new_player_info
	which_signal.emit(player_id, new_player_info,extra_index)

@rpc("any_peer", "reliable")
func draw_card(card_index,extra_index,remote_info):
	if multiplayer.get_remote_sender_id()!=multiplayer.get_unique_id():
		for card in player_info["cards"]:
			if card == card_index:
				player_info["cards"].erase(card)
				break
		_update_player_info(remote_info,player_1_info_updated,extra_index)
		_update_player_info(player_info,player_this_info_updated,extra_index)

func _on_peer_disconnected(id):
	players.erase(id)
	player_disconnected.emit(id)

func _on_connected_to_server():
	pass

@rpc("any_peer", "reliable", "call_remote")
func receive_return_data(cards,player_1_info):
	if not multiplayer.is_server():
		var peer_id = multiplayer.get_unique_id()
		player_info["cards"] = cards
		players[peer_id] = player_info
		player_connected.emit(peer_id, player_info)
		player_connected.emit(1, player_1_info)


func _on_connection_failed():
	multiplayer.multiplayer_peer = null


func _on_server_disconnected():
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()


func pre_cards():
	for clr in range(1, 3):
		for ct in range(1, 14):
			pre_deal_card_dict[str(clr)][ct - 1] = {"value": str(ct), "color": clr}


func deal_cards():
	var pre_cards_dict={}
	for i in range(1, 14):
		pre_cards_dict[i] = {"value": str(i), "color": 1}
	for i in range(1, 14):
		pre_cards_dict[i+13] = {"value": str(i), "color": 2}
	pre_cards_dict=shuffle_dictionary(pre_cards_dict)
	for i in range(0, 13):
		player_cards_1[i] = pre_cards_dict[i+1]
		player_cards_2[i] = pre_cards_dict[i+14]
	if random_bool(0.5):
		player_cards_1[len(player_cards_1)] = {"value": "jk", "color": 1}
	else:
		player_cards_2[len(player_cards_2)] = {"value": "jk", "color": 1}

func random_bool(probability: float) -> bool:
	var randomValue = randf()
	return randomValue < probability

func shuffle_dictionary(dict):
	var keys = dict.keys()
	keys.shuffle()

	var i = 1
	var shuffled_dict = {}
	for key in keys:
		shuffled_dict[i] = dict[key]
		if i > len(dict):
			break
		i += 1

	print("------------------")
	print(shuffled_dict)
	print("------------------")
	return shuffled_dict
