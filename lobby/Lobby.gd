extends Node3D
class_name Lobby

@export var selected_world: PackedScene

@onready var players:Node3D = $Players
@onready var host: Button = %Host
@onready var join: Button = %Join
@onready var spawn_area: Area3D = $SpawnArea

var player_scene: PackedScene = preload("res://player/Player.tscn")
var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

var player_character: Character
# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func set_peer_character(character: Character):
	player_character = character			
	

@rpc("call_local", "any_peer")
func add_player(peer_id: int, character_scene_file_path: String):	

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
		found_player.set_character(character_scene) 
		
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_start_game_pressed():
	
	#var world = selected_world.instantiate()
	#get_tree().root.add_child(world)

#	var packed_scene: PackedScene = PackedScene.new()
#	selected_character.position = Vector3.ZERO
#	selected_character.rotation = Vector3.ZERO
#
#	packed_scene.pack(selected_character)
	
	#world.set_player_character(packed_scene)
	
	#get_tree().root.remove_child(self)
	pass


func _on_host_pressed():
	enet_peer.create_server(9998)
	multiplayer.multiplayer_peer = enet_peer	
	add_player.rpc(multiplayer.get_unique_id(), player_character.scene_file_path)
	multiplayer.peer_connected.connect(
		func(peer_id:int):
			add_player.rpc(multiplayer.get_unique_id(), player_character.scene_file_path)
	)

func _on_join_pressed():
	enet_peer.create_client("127.0.0.1", 9998)
	multiplayer.multiplayer_peer = enet_peer
	multiplayer.connected_to_server.connect(
		func(): 
			add_player.rpc(multiplayer.get_unique_id(), player_character.scene_file_path)
	)
	
