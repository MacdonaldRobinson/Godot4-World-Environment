extends Node3D
class_name Lobby

@onready var players:Node3D = $Players
@onready var host: Button = %Host
@onready var join: Button = %Join
@onready var spawn_area: Area3D = $SpawnArea
@onready var chat_overlay: ChatOverlay = %ChatOverlay as ChatOverlay
@onready var host_join_buttons: Control = %Host_Join
@onready var world_selecter: Control = %WorldSelecter
@onready var worlds_list: ItemList = %WorldList as ItemList

var worlds: Dictionary = {
	"Mountain" = "res://worlds/WorldOne/WorldOne.tscn",
	"Garage" = "res://worlds/WorldTwo/WorldTwo.tscn",
}

@onready var camera: Camera3D = $Camera3D

var player_scene: PackedScene = preload("res://player/Player.tscn")
var character_selecter: PackedScene = preload("res://character-selector/CharacterSelector.tscn")

var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var selected_world: String

# Called when the node enters the scene tree for the first time.
func _ready():
	chat_overlay.hide()
	worlds_list.clear()
	world_selecter.hide()
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera.current = true
	
	for world in worlds:
		if world is String:
			worlds_list.add_item(world)
	pass

@rpc("call_remote", "any_peer")
func remove_player(peer_id: int):	
	if players.has_node(str(peer_id)):
		var found_player: Player = players.get_node(str(peer_id)) as Player
		if found_player:
			players.remove_child(found_player)
			
			var my_player: Player = players.get_node(str(multiplayer.get_unique_id())) as Player
			
			if my_player:
				chat_overlay.set_players(players.get_children(), my_player)

@rpc("call_local","any_peer")
func add_player(peer_id: int, character_scene_file_path: String, character_name: String):
#	print("executed on peer : ",multiplayer.get_unique_id(),
#	" | peer_id : ", peer_id,
#	" | character_scene_file_path : ", character_scene_file_path,
#	" | character_name : ", character_name,
#	" | peers_connected : ", multiplayer.get_peers()," \r\n")
	
	if(not players.has_node(str(peer_id))):
		if peer_id == multiplayer.get_unique_id():
			GameState.my_player.name = str(peer_id)
			GameState.set_my_player_character_name(character_name)
			GameState.move_my_player_to_container(players)
		else:
			var player: Player = player_scene.instantiate() as Player
			player.name = str(peer_id)
			players.add_child(player)
			
			player.position = Vector3(players.get_child_count() * 2, 0, 0)
			player.rotation = Vector3.ZERO
	
	if(players.has_node(str(peer_id))):
		var found_player: Player = players.get_node(str(peer_id)) as Player
		
		for child in found_player.get_children():
			if child is Character:
				return
		
		var character: Character = ResourceLoader.load(character_scene_file_path).instantiate()
		character.character_name = character_name
		found_player.set_character(character) 
		
	chat_overlay.set_players(players.get_children(), GameState.my_player)
		
	if multiplayer.is_server():
		var connected_peers = multiplayer.get_peers()
		for connected_peer_id in connected_peers:
			if connected_peer_id != peer_id:
				# Add new peer to existing peers
				var peer_player: Player = players.get_node(str(peer_id)) as Player
				add_player.rpc_id(connected_peer_id, peer_id, peer_player.character.scene_file_path, peer_player.character.character_name)
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
@rpc("call_local", "any_peer")
func start_game(selected_world_index: int):	
	_on_world_list_item_selected(selected_world_index)
	
	GameState.switch_to_scene(
		selected_world, 
		func(world: World): 
			world.set_players(players.get_children(), GameState.my_player)			
			GameState.is_game_started = true
	)

func _on_start_game_pressed():	
	var selected_items = worlds_list.get_selected_items()
	
	if selected_items.size() > 0:
		start_game.rpc(selected_items[0])
		
	pass


func _on_host_pressed():
	NetworkState.start_network(true)
	
	add_player(multiplayer.get_unique_id(), GameState.my_player.character.scene_file_path, GameState.my_player.character.character_name)
	host_join_buttons.hide()
	chat_overlay.show()
	world_selecter.show()	
	
	multiplayer.peer_connected.connect(
		func(peer_id:int): 
			for player in players.get_children():
				if player is Player:
					if player.name != str(peer_id):
						# Add existing peers to new peer
						add_player.rpc_id(peer_id, player.name.to_int(), player.character.scene_file_path, player.character.character_name)
	)
	
	multiplayer.peer_disconnected.connect(
		func(peer_id: int):
			if self:
				remove_player.rpc(peer_id)
	)

func _on_join_pressed():	
	NetworkState.start_network(false)
	
	world_selecter.show()	
	
	multiplayer.connected_to_server.connect(
		func():
			# Add my player to all peers
			# Seems to only call the server, so had to send to existing players from the add_player from the server
			if multiplayer:
				add_player.rpc(multiplayer.get_unique_id(), GameState.my_player.character.scene_file_path, GameState.my_player.character.character_name)
			pass
	)
		
	
	host_join_buttons.hide()
	chat_overlay.show()
	

func _on_world_list_item_selected(index):	
	var selected_list_item = worlds_list.get_item_text(index)
	selected_world = worlds[selected_list_item]
	pass
	

func _on_character_selecter_pressed():	
	GameState.move_my_player_to_gamestate()
	remove_player.rpc(multiplayer.get_unique_id())
	
	get_tree().change_scene_to_packed(character_selecter)
	get_tree().root.remove_child(self)
