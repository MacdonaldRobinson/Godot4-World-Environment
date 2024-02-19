extends Node

var is_game_started: bool = false
var inventory: Inventory = Inventory.new() as Inventory
var chat_messages: Array[ChatMessage]

@export var all_players_info: Array[PlayerInfo]
@onready var scene_loader: SceneLoader = %SceneLoader
@onready var players_container: Node3D = %PlayersContainer

var player_scene: PackedScene = preload("res://player/Player.tscn")
var character_selecter: PackedScene = preload("res://character-selector/CharacterSelector.tscn")
	
signal OnPlayerAdded(player_info: PlayerInfo)
signal OnPlayerRemoved(player_info: PlayerInfo)
signal OnPlayerUpdated(player_info: PlayerInfo)
signal OnChatMessageAdded(chat_message: ChatMessage)

func _ready():
	scene_loader.hide()	
	
func set_my_player_character(selected_character: Character, my_character_name: String):
	var my_player_info: PlayerInfo = get_my_player_info()
	
	if not my_player_info:
		my_player_info = PlayerInfo.new()
		my_player_info.peer_id = multiplayer.get_unique_id()
		
	my_player_info.character_name = my_character_name
	my_player_info.character_photo = selected_character.character_photo
	my_player_info.character_scene_file_path = selected_character.scene_file_path
	my_player_info.health = 100
	
	GameState.add_or_update_player_info(var_to_str(my_player_info))
	

func set_my_player_character_name(my_character_name: String):
	var my_player_info: PlayerInfo = get_my_player_info()
	my_player_info.character_name = my_character_name
	
	GameState.add_or_update_player_info(var_to_str(my_player_info))

func switch_to_scene(new_scene_path: String, callback: Callable = func(arg): pass):
	var current_scene: Node = get_current_scene()	
	current_scene.hide()

	scene_loader.show()
	
	scene_loader.load_scene(
		new_scene_path, 
		func(new_scene: Node):
					
			new_scene.reparent(get_tree().root)
			scene_loader.hide()
			
			callback.call(new_scene)
			
			current_scene.queue_free()
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
		
	if multiplayer.is_server():
		var connected_peers = multiplayer.get_peers()
		for connected_peer_id in connected_peers:
			if connected_peer_id != player_info.peer_id:
				# Add new peer to existing peers
				add_or_update_player_info.rpc_id(connected_peer_id, var_to_str(player_info))


func remove_player_info(peer_id: int):
	var player_info_index: int = get_player_info_index(peer_id)	
	all_players_info.remove_at(player_info_index)
	
func get_my_player_info() -> PlayerInfo:
	var player_info: PlayerInfo = GameState.get_player_info(multiplayer.get_unique_id())	
	
	if not player_info and all_players_info.size() == 1:
		return all_players_info[0]
	
	return player_info

func get_player_in_container(peer_id: int, container: Node) -> Player:
	var player_info: PlayerInfo = get_player_info(peer_id)
	for child in container.get_children():
		if child.name == str(player_info.peer_id):
			return child
			
	return null

func get_my_player_in_container(container: Node) -> Player:
	var my_player_info: PlayerInfo = get_my_player_info()
	var my_player: Player = get_player_in_container(my_player_info.peer_id, container)
			
	return my_player
	

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

func log(message: String):
	var function_chain: String
	
	for item in get_stack():
		function_chain += item.function + " -> "
	
	print("On: ", multiplayer.get_unique_id(), " Remote: ", multiplayer.get_remote_sender_id(), " Stack: ", function_chain, "\nMessage: "+ message +"\n\n")
			
func add_or_update_player_in_container(player_info: PlayerInfo, players_container: Node3D) -> Player:	
	var str_peer_id: String = str(player_info.peer_id)
	var player: Player
	
	if(not players_container.has_node(str_peer_id)):
		player = GameState.player_scene.instantiate()
		players_container.add_child(player)		
	else:
		player = players_container.get_node(str_peer_id)	
	
	player.set_player_info(player_info)
		
	return player
				
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
