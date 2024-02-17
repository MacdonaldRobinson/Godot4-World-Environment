extends Node

var is_game_started: bool = false
var inventory: Inventory = Inventory.new() as Inventory
var chat_messages: Array[ChatMessage]
var all_players_info: Array[PlayerInfo]

@onready var scene_loader: SceneLoader = %SceneLoader

var player_scene: PackedScene = preload("res://player/Player.tscn")
var character_selecter: PackedScene = preload("res://character-selector/CharacterSelector.tscn")
var my_player: Player 

signal OnPlayerAdded(player_info: PlayerInfo)
signal OnPlayerRemoved(player_info: PlayerInfo)
signal OnPlayerUpdated(player_info: PlayerInfo)
signal OnChatMessageAdded(chat_message: ChatMessage)

func _ready():
	scene_loader.hide()	
	
func set_my_player_character(selected_character: Character, my_character_name: String):
	if not my_player:
		my_player = player_scene.instantiate()
	
	var my_character: Character = selected_character.duplicate() as Character

	my_character.position = Vector3.ZERO
	my_character.rotation = Vector3.ZERO
	my_character.character_name = my_character_name
	
	my_player.set_character(my_character)
	

func set_my_player_character_name(my_character_name: String):
	my_player.character.character_name = my_character_name

func start_my_player_process():
	GameState.my_player.set_physics_process(true)
	GameState.my_player.set_process(true)	
	
func stop_my_player_process():
	GameState.my_player.set_physics_process(false)
	GameState.my_player.set_process(false)	
	
func reset_my_player_position_to_zero():
	GameState.my_player.position = Vector3.ZERO
	GameState.my_player.rotation = Vector3.ZERO	

func switch_to_scene(new_scene_path: String, callback: Callable = func(arg): pass):
	var current_scene: Node = get_current_scene()
	
	get_tree().root.remove_child(current_scene)
	scene_loader.show()
	
	scene_loader.load_scene(
		new_scene_path, 
		func(new_scene: Node):
			callback.call(new_scene)
									
			get_tree().root.remove_child(current_scene)
			new_scene.reparent(get_tree().root)
						
			scene_loader.hide()
	)	
		
@rpc("call_remote", "any_peer")
func remove_player(peer_id: int):
	var existing_player_info: PlayerInfo = get_player_info(peer_id)
	
	if existing_player_info:
		remove_player_info(peer_id)
		OnPlayerRemoved.emit(existing_player_info)

@rpc("call_local","any_peer")
func add_or_update_player_info(player_info_str: String):
	var player_info: PlayerInfo = str_to_var(player_info_str)
	_add_or_update_player_info(player_info)	

func _add_or_update_player_info(player_info: PlayerInfo):	
	var found_existing_player_info: PlayerInfo = get_player_info(player_info.peer_id)

	if found_existing_player_info:
		found_existing_player_info.character_name = player_info.character_name
		found_existing_player_info.character_name = player_info.character_name
		found_existing_player_info.health = player_info.health
		found_existing_player_info.character_scene_file_path = player_info.character_scene_file_path
		found_existing_player_info.is_in_game = player_info.is_in_game
		
		OnPlayerUpdated.emit(player_info)
	else:
		all_players_info.push_back(player_info)
		OnPlayerAdded.emit(player_info)		

func remove_player_info(peer_id: int):
	var player_info_index: int = get_player_info_index(peer_id)	
	all_players_info.remove_at(player_info_index)
	
func get_my_player_info() -> PlayerInfo:
	var player_info: PlayerInfo = GameState.get_player_info(multiplayer.get_unique_id())
	return player_info
	
func get_player_info(peer_id: int) -> PlayerInfo:
	for index in range(all_players_info.size()):
		var existing_player_info: PlayerInfo = all_players_info[index]
		if existing_player_info.peer_id == peer_id:
			return existing_player_info
			
	return null
			
func get_player_info_index(peer_id: int) -> int:
	for index in range(all_players_info.size()):
		var existing_player_info: PlayerInfo = all_players_info[index]
		if existing_player_info.peer_id == peer_id:
			return index
			
	return -1

func remove_player_from_container(peer_id: int, players_container: Node3D):	
	if players_container.has_node(str(peer_id)):
		var found_player: Player = players_container.get_node(str(peer_id)) as Player
		if found_player:
			players_container.remove_child(found_player)
			
func add_or_update_player_in_container(player_info: PlayerInfo, players_container: Node3D):	
	var str_peer_id: String = str(player_info.peer_id)
	
	if(not players_container.has_node(str_peer_id)):
		if player_info.peer_id == multiplayer.get_unique_id():
			GameState.my_player.name = str_peer_id
			GameState.set_my_player_character_name(player_info.character_name)
			
			players_container.add_child(GameState.my_player)
		else:
			var player: Player = player_scene.instantiate() as Player
			player.name = str_peer_id
				
			players_container.add_child(player)
			
			player.position = Vector3(players_container.get_child_count() * 2, 0, 0)
			player.rotation = Vector3.ZERO
	
	if(players_container.has_node(str_peer_id)):
		var found_player: Player = players_container.get_node(str_peer_id) as Player
		
		for child in found_player.get_children():
			if child is Character:
				return
		
		var character: Character = ResourceLoader.load(player_info.character_scene_file_path).instantiate()
		character.character_name = player_info.character_name
		found_player.set_character(character)
	
	
	if multiplayer.is_server():
		var connected_peers = multiplayer.get_peers()
		for connected_peer_id in connected_peers:
			if connected_peer_id != player_info.peer_id:
				# Add new peer to existing peers
				var peer_player: Player = players_container.get_node(str_peer_id) as Player				
				add_or_update_player_info.rpc_id(connected_peer_id, var_to_str(player_info))
				
				
@rpc("call_local","any_peer")
func add_chat_message(sender_name: String, message: String):
	var chat_message: ChatMessage = ChatMessage.new()
	chat_message.peer_id = str(multiplayer.get_remote_sender_id())
	chat_message.sender_name = sender_name
	chat_message.message = message
	
	chat_messages.push_back(chat_message)
		
	OnChatMessageAdded.emit(chat_message)
				
func _process(delta):
	pass

func leave():	
	GameState.remove_player.rpc(multiplayer.get_unique_id())
	GameState.all_players_info.clear()
	
	for connection in GameState.OnPlayerAdded.get_connections():
		GameState.OnPlayerAdded.disconnect(connection["callable"])

	for connection in GameState.OnPlayerUpdated.get_connections():
		GameState.OnPlayerUpdated.disconnect(connection["callable"])

	for connection in GameState.OnPlayerRemoved.get_connections():
		GameState.OnPlayerUpdated.disconnect(connection["callable"])

	for connection in GameState.OnChatMessageAdded.get_connections():
		GameState.OnPlayerUpdated.disconnect(connection["callable"])
		
	GameState.my_player.queue_free()
	
	get_tree().change_scene_to_packed(GameState.character_selecter)
	get_current_scene().queue_free()

func get_current_scene() -> Node3D:
	for scene in get_tree().root.get_children():
		if scene is Node3D:
			return scene
			
	return null
	
func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
			
func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
