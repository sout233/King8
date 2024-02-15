extends Node2D

@export var main_layer: CanvasLayer
@export var card_scene: PackedScene
@export var bottom_card_stack: Node2D
@export var top_card_stack: Node2D
@export var win_view: Control
@export var ip_text_edit: TextEdit
@export var port_text_edit: TextEdit

var bottom_start_pos: Vector2 = Vector2(50, 530)
var top_start_pos: Vector2 = Vector2(50, 100)
var player_this_info = {}:
	set(value):
		player_this_info = value
		MultiplayController.player_info = value
var player_1_info = {}
var increse_num = 114514
var is_game_started := false

func _ready() -> void:
	MultiplayController.IPTextEdit= ip_text_edit
	MultiplayController.PortTextEdit= port_text_edit
	MultiplayController.player_connected.connect(on_player_connected)
	MultiplayController.player_1_info_updated.connect(on_player_1_info_updated)
	MultiplayController.player_this_info_updated.connect(on_player_this_info_updated)


func _process(_delta) -> void:
	pass


func hand_out_cards(cards: Dictionary, where: int) -> void:
	var count = cards.size()
	for i_count in range(0, count):
		var _card: Card = card_scene.instantiate()
		_card.card_index = i_count

		_card.card_color = cards[i_count]["color"]

		if cards[i_count]["value"] == "1":
			_card.card_name = "ACE"
		elif cards[i_count]["value"] == "11":
			_card.card_name = "J"
		elif cards[i_count]["value"] == "12":
			_card.card_name = "Q"
		elif cards[i_count]["value"] == "13":
			_card.card_name = "K"
		else:
			_card.card_name = cards[i_count]["value"]

		await get_tree().create_timer(0.1).timeout
		if where == 0:
			_card.global_position = bottom_start_pos
			_card.checkable = true
			bottom_start_pos.x += 50
			bottom_card_stack.position.x += 10
			bottom_card_stack.add_child(_card)
		elif where == 1:
			_card.global_position = top_start_pos
			_card.checkable = true
			_card.card_sprite.texture=load(King8Helper.get_card_path(""))
			top_start_pos.x += 50
			top_card_stack.position.x += 10
			top_card_stack.add_child(_card)
	if where == 0:
		tween_pos_to_center(bottom_card_stack, count)
	elif where == 1:
		tween_pos_to_center(top_card_stack, count)


func tween_pos_to_center(target: Node2D, count: int) -> void:
	var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_ELASTIC)
	var new_pos: Vector2 = Vector2(get_viewport_rect().size.x / 2 - (count * 50.0 + 24.0) / 2, 0)
	tween.tween_property(target, "position", new_pos, 1.0)


func on_player_connected(_peer_id, _player_info) -> void:
	if _peer_id == multiplayer.get_unique_id():
		player_this_info = _player_info
		hand_out_cards(_player_info["cards"], 0)
	else:
		player_1_info = _player_info
		hand_out_cards(_player_info["cards"], 1)


func on_player_1_info_updated(player_id, new_player_info,extra_index) -> void:
	if player_id != multiplayer.get_unique_id():
		player_1_info = new_player_info

		for card in top_card_stack.get_children():
			if new_player_info["cards"].get(card.card_index) == null:
				card.reparent(get_parent())
				var tween = get_tree().create_tween()
				tween.parallel().tween_property(card, "modulate", Color.TRANSPARENT, 0.2)
				tween.parallel().tween_property(
					card, "position", Vector2(card.position.x, card.position.y + 50), 0.4
				)
				tween.tween_callback(card.queue_free)
		for card in new_player_info["cards"]:
			if card == extra_index and extra_index!=NAN:
				var new_card = card_scene.instantiate()
				new_card.card_index = card
				new_card.card_name = new_player_info["cards"][card]["value"]
				new_card.card_sprite.texture=load(King8Helper.get_card_path(""))
				new_card.position.x = len(new_player_info["cards"])*50+50
				top_card_stack.add_child(new_card)

		push_cards(top_card_stack, player_1_info, top_start_pos,true,true)

func on_player_this_info_updated(player_id,new_player_info,_extra_index)->void:
	if player_id != multiplayer.get_unique_id():
		player_this_info = new_player_info

		for card in bottom_card_stack.get_children():
			if new_player_info["cards"].get(card.card_index) == null:
				card.reparent(get_parent())
				var tween = get_tree().create_tween()
				tween.parallel().tween_property(card, "modulate", Color.TRANSPARENT, 0.2)
				tween.parallel().tween_property(
					card, "position", Vector2(card.position.x, card.position.y - 50), 0.4
				)
				tween.tween_callback(card.queue_free)

		push_cards(bottom_card_stack, player_this_info, bottom_start_pos,true,true)


func push_cards(card_stack: Node2D, player_info, start_pos: Vector2,is_draw:bool=false,is_delete:bool=true) -> Dictionary:
	var card_checked_list = []
	for card in card_stack.get_children():
		if card is Card:
			if card.is_check == true:
				card_checked_list.append(card)

	if is_draw:
		for card in card_checked_list:
			var tween = get_tree().create_tween()
			card.reparent(get_parent())
			card.checkable = false
			player_info["cards"].erase(card.card_index)
			tween.parallel().tween_property(card, "modulate", Color.TRANSPARENT, 0.2)
			tween.parallel().tween_property(
				card, "position", Vector2(card.position.x, card.position.y + 50), 0.4
			)
			if is_delete:
				tween.tween_callback(card.queue_free)
	elif len(card_checked_list) != 2:
		print("selected count not eq 2"+str(multiplayer.get_unique_id()))
		return {}
	elif card_checked_list[0].card_name != card_checked_list[1].card_name:
		print("selected cards not eq")
		return {}
	else:
		for card in card_checked_list:
			var tween = get_tree().create_tween()
			card.reparent(get_parent())
			card.checkable = false
			player_info["cards"].erase(card.card_index)
			tween.parallel().tween_property(card, "modulate", Color.TRANSPARENT, 0.2)
			tween.parallel().tween_property(
				card, "position", Vector2(card.position.x, card.position.y - 50), 0.4
			)
			if is_delete:
				tween.tween_callback(card.queue_free)

	for card in card_checked_list:
		card.is_check=false

	reset_cards(card_stack,start_pos)

	tween_pos_to_center(card_stack, player_info["cards"].size())

	if bottom_card_stack.get_children() == [] and is_game_started:
		win_view.visible=true
		win_view.get_node("WinLabel").text = "U WIN"
	elif top_card_stack.get_children() == [] and is_game_started:
		win_view.visible=true
		win_view.get_node("WinLabel").text = "U LOSE"

	return player_info

func reset_cards(card_stack,start_pos):
	var _new_pos: Vector2 = Vector2(50, start_pos.y)

	await get_tree().create_timer(0.1).timeout

	for card in card_stack.get_children():
		if card is Card:
			card.is_check=false
			var tween = get_tree().create_tween().bind_node(self).set_trans(Tween.TRANS_ELASTIC)
			tween.tween_property(card, "position", _new_pos, 1.0)
			card.rem_pos=_new_pos
			_new_pos.x += 50

func select_double():
	for card in bottom_card_stack.get_children():
		card.is_check=false
	for card in bottom_card_stack.get_children():
		for card2 in bottom_card_stack.get_children():
			if card==card2:
				continue
			elif card.card_name == card2.card_name:
				card.is_check=true
				card2.is_check=true
				return

func draw_card():
	for card in bottom_card_stack.get_children():
		card.is_check=false
	for card in top_card_stack.get_children():
		if card.is_check:
			is_game_started = true
			for player in MultiplayController.players:
				if player!=multiplayer.get_unique_id():
					MultiplayController.change_round.rpc(player)
					MultiplayController.round_id = player
			var new_card:Card = card_scene.instantiate()
			new_card.card_color=card.card_color
			new_card.card_index=card.card_index
			new_card.card_name=card.card_name
			new_card.position = card.position
			bottom_card_stack.add_child(new_card)
			player_1_info["cards"].erase(card.card_index)
			push_cards(top_card_stack, player_1_info, top_start_pos,true)
			push_cards(bottom_card_stack, player_this_info, bottom_start_pos,true,false)
			for i in range(0,len(player_this_info["cards"])):
				if i+1==len(player_this_info["cards"]):
					increse_num+=1
					player_this_info["cards"][increse_num]={"value":card.card_name,"color":card.card_color}
			new_card.card_index=increse_num
			MultiplayController.draw_card.rpc(card.card_index,new_card.card_index,player_this_info)
			return


func _on_play_push_button_pressed():
	var _player_this_info = push_cards(bottom_card_stack, player_this_info, bottom_start_pos)
	if _player_this_info!={}:
		player_this_info=_player_this_info
		print(player_this_info)

@rpc("any_peer", "reliable", "call_remote")
func move_card_left(checked_index:int,where):
	var child_index:int = 0
	var card_stack

	if where==0:
		card_stack=bottom_card_stack
	else:
		card_stack=top_card_stack

	for card in card_stack.get_children():
		if card.card_index==checked_index:
			if card.get_index()<=0:
				return
			# card.is_check=false
			card.position.x-=50
			card_stack.move_child(card,card.get_index()-1)
			child_index-=1
			break
		child_index+=1
	print(child_index)
	var justify_node = card_stack.get_child(child_index+1)
	justify_node.position.x+=50

@rpc("any_peer", "reliable", "call_remote")
func move_card_right(checked_index:int,where):
	var child_index:int = 0
	var card_stack

	if where==0:
		card_stack=bottom_card_stack
	else:
		card_stack=top_card_stack

	for card in card_stack.get_children():
		if card.card_index==checked_index:
			if card.get_index()>=card_stack.get_child_count()-1:
				return
			# card.is_check=false
			card.position.x+=50
			card_stack.move_child(card,card.get_index()+1)
			child_index+=1
			break
		child_index+=1
	print(child_index)
	var justify_node = card_stack.get_child(child_index-1)
	justify_node.position.x-=50


func _on_select_double_button_pressed():
	select_double()

func _on_draw_button_pressed():
	draw_card()


func _on_left_move_button_pressed():
	var checked_index = []
	for card in bottom_card_stack.get_children():
		if card.is_check:
			checked_index.append(card.card_index)
	if len(checked_index)!=1:
		for card in bottom_card_stack.get_children():
			card.is_check=false
		return
	move_card_left(checked_index[0],0)
	move_card_left.rpc(checked_index[0],1)


func _on_right_move_button_pressed():
	var checked_index = []
	for card in bottom_card_stack.get_children():
		if card.is_check:
			checked_index.append(card.card_index)
	if len(checked_index)!=1:
		for card in bottom_card_stack.get_children():
			card.is_check=false
		return
	move_card_right(checked_index[0],0)
	move_card_right.rpc(checked_index[0],1)