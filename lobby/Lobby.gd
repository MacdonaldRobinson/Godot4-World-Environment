extends Node3D
class_name Lobby


@onready var players:Node3D = $Players
@onready var host: Button = %Host
@onready var join: Button = %Join
@onready var spawn_area: Area3D = $SpawnArea
@onready var chat_overlay: ChatOverlay = %ChatOverlay as ChatOverlay
@onready var host_join_buttons: Control = %Host_Join
@onready var worlds_list: ItemList = %WorldList as ItemList

var worlds: Array[World] = [
	preload("res://worlds/WorldOne/WorldOne.tscn").instantiate(),
	preload("res://worlds/WorldTwo/WorldTwo.tscn").instantiate(),
] as Array[World]

@onready var camera: Camera3D = $Camera3D

var player_scene: PackedScene = preload("res://player/Player.tscn")
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var selected_world: World
var player_character: Character

# Called when the node enters the scene tree for the first time.
func _ready():
	chat_overlay.hide()
	worlds_list.clear()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera.current = true
	
	for world in worlds:
		if world is World:
			worlds_list.add_item(world.name)
	pass

func set_peer_character(character: Character):
	player_character = character			
	
func get_my_player() ->Player:
	return players.get_node(str(multiplayer.get_unique_id())) as Player

@rpc("call_local", "any_peer")
func add_player(peer_id: int, character_scene_file_path: String, character_name: String):	

	if(not players.has_node(str(peer_id))):
		var player: Player = player_scene.instantiate() as Player
		player.name = str(peer_id)
		
		var spawn_position = Vector3(players.get_child_count() + 1, 0, 0)
		print(player.name, spawn_position)
		player.position = spawn_position
		player.rotation = Vector3.ZERO
		
		players.add_child(player)
	
	if(players.has_node(str(peer_id))):
		var found_player: Player = players.get_node(str(peer_id)) as Player
		
		for child in found_player.get_children():
			if child is Character:
				return
		
		var character_scene = ResourceLoader.load(character_scene_file_path)		
		found_player.set_character(character_scene, character_name) 
		
		var me: Player = players.get_node(str(multiplayer.get_unique_id())) as Player
		chat_overlay.set_players(players.get_children(), me)
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
@rpc("call_local", "any_peer")
func start_game(selected_world_index: int):	
	_on_world_list_item_selected(selected_world_index)
			
	get_tree().root.add_child(selected_world)
	
	selected_world.set_players(players.get_children(), get_my_player())

	get_tree().root.remove_child(self)

func _on_start_game_pressed():	
	start_game.rpc(worlds_list.get_selected_items()[0])
	pass


func _on_host_pressed():
	enet_peer.create_server(9998)
	multiplayer.multiplayer_peer = enet_peer	
	add_player.rpc(multiplayer.get_unique_id(), player_character.scene_file_path, player_character.character_name)
	host_join_buttons.hide()
	chat_overlay.show()
	multiplayer.peer_connected.connect(
		func(peer_id:int):			
			add_player.rpc(multiplayer.get_unique_id(), player_character.scene_file_path, player_character.character_name)
	)

func _on_join_pressed():
	enet_peer.create_client("127.0.0.1", 9998)
	multiplayer.multiplayer_peer = enet_peer
	host_join_buttons.hide()
	chat_overlay.show()
	multiplayer.connected_to_server.connect(
		func(): 
			add_player.rpc(multiplayer.get_unique_id(), player_character.scene_file_path, player_character.character_name)		
	)
	

func _on_world_list_item_selected(index):
	selected_world = worlds[index]
	pass
	
