extends Node

var my_player: Player
var is_game_started: bool = false
var inventory: Inventory = Inventory.new() as Inventory

@onready var players_container: Node3D = %PlayersContainer
@onready var scene_loader: Control = %SceneLoader

var player_scene: PackedScene = preload("res://player/Player.tscn")
var character_selecter: PackedScene = preload("res://character-selector/CharacterSelector.tscn")

signal OnPlayerAdded(player: Player)
signal OnPlayerRemoved(player: Player)

func _ready():
	players_container.hide()
	scene_loader.hide()
	
	my_player = preload("res://player/Player.tscn").instantiate() as Player
	players_container.add_child(my_player)	
	
	GameState.stop_my_player_process()
	
func set_my_player_character(selected_character: Character, my_character_name: String):
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
	if players_container.has_node(str(peer_id)):
		var found_player: Player = players_container.get_node(str(peer_id)) as Player
		if found_player:
			players_container.remove_child(found_player)
			
			OnPlayerRemoved.emit(found_player)


@rpc("call_local","any_peer")
func add_player(peer_id: int, character_scene_file_path: String, character_name: String):
	if(not players_container.has_node(str(peer_id))):
		if peer_id == multiplayer.get_unique_id():
			GameState.my_player.name = str(peer_id)
			GameState.set_my_player_character_name(character_name)
			
			GameState.players_container.add_child(GameState.my_player)
			
			OnPlayerAdded.emit(GameState.my_player)
		else:
			var player: Player = player_scene.instantiate() as Player
			player.name = str(peer_id)
			players_container.add_child(player)
			
			player.position = Vector3(players_container.get_child_count() * 2, 0, 0)
			player.rotation = Vector3.ZERO
			
	
	if(players_container.has_node(str(peer_id))):
		var found_player: Player = players_container.get_node(str(peer_id)) as Player
		
		for child in found_player.get_children():
			if child is Character:
				return
		
		var character: Character = ResourceLoader.load(character_scene_file_path).instantiate()
		character.character_name = character_name
		found_player.set_character(character) 
		
		OnPlayerAdded.emit(found_player)
	
	
	if multiplayer.is_server():
		var connected_peers = multiplayer.get_peers()
		for connected_peer_id in connected_peers:
			if connected_peer_id != peer_id:
				# Add new peer to existing peers
				var peer_player: Player = players_container.get_node(str(peer_id)) as Player
				add_player.rpc_id(connected_peer_id, peer_id, peer_player.character.scene_file_path, peer_player.character.character_name)
				
				
func _process(delta):
	pass
	

func leave():
	GameState.remove_player.rpc(multiplayer.get_unique_id())
	
	for player in GameState.players_container.get_children():
		GameState.players_container.remove_child(player)		
	
	get_tree().change_scene_to_packed(GameState.character_selecter)
	get_tree().root.remove_child(get_current_scene())

func get_current_scene() -> Node3D:
	for scene in get_tree().root.get_children():
		if scene is Node3D:
			return scene
			
	return null
	
func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
			
func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
