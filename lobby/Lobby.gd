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

var enet_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var selected_world: String

# Called when the node enters the scene tree for the first time.
func _ready():
	chat_overlay.hide()
	worlds_list.clear()
	world_selecter.hide()
	
	GameState.OnPlayerAdded.connect(
		func(player: Player):
			print("Player Added: ", player.name, " on: ", GameState.my_player.name," count: " ,GameState.players_container.get_child_count())
			chat_overlay.set_players(GameState.players_container.get_children(), GameState.my_player)
			
			var found_player: Player
			
			for existing_player in players.get_children():
				if existing_player.name == player.name:
					found_player = existing_player
					break
			
			if not found_player:
				var instance: Player = player.duplicate()
				var character: Character = player.character.duplicate()
				instance.set_character(character)
				
				players.add_child(instance)
			else:
				var character: Character = player.character.duplicate()
				found_player.set_character(character)
			
	)
	
	GameState.OnPlayerRemoved.connect(
		func(player: Player):
			print("Player Removed: ", player.name, " on: ", GameState.my_player.name," count: " ,GameState.players_container.get_child_count())
			chat_overlay.set_players(GameState.players_container.get_children(), GameState.my_player)
			
			for existing_player in players.get_children():
				if existing_player.name == player.name:
					players.remove_child(existing_player)
	)	
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera.current = true
	
	for world in worlds:
		if world is String:
			worlds_list.add_item(world)
	pass

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

	chat_overlay.set_players(GameState.players_container.get_children(), GameState.my_player)

	host_join_buttons.hide()
	chat_overlay.show()
	world_selecter.show()	
	

func _on_join_pressed():
	NetworkState.start_network(false)
	
	chat_overlay.set_players(GameState.players_container.get_children(), GameState.my_player)

	world_selecter.show()	
	
	host_join_buttons.hide()
	chat_overlay.show()
	

func _on_world_list_item_selected(index):	
	var selected_list_item = worlds_list.get_item_text(index)
	selected_world = worlds[selected_list_item]
	pass
	

func _on_character_selecter_pressed():	
	GameState.leave()

