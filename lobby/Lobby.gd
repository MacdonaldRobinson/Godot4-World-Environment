extends Node3D
class_name Lobby

@onready var players_container:Node3D = %PlayersContainer
@onready var host: Button = %Host
@onready var join: Button = %Join
@onready var spawn_area: Area3D = $SpawnArea

@onready var host_join_container: Control = %HostJoinContainer
@onready var host_container: Control = %HostContainer

@onready var host_external_ip: TextEdit = %HostExternalIP
@onready var host_port: TextEdit = %HostPort

@onready var join_container: Control = %JoinContainer
@onready var join_external_ip: TextEdit = %JoinExternalIP
@onready var join_port: TextEdit = %JoinPort


@onready var world_selecter: Control = %WorldSelecter
@onready var worlds_list: ItemList = %WorldList as ItemList
@onready var chat_overlay: ChatOverlay = %ChatOverlay

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
	
	for child in players_container.get_children():
		players_container.remove_child(child)
	
	GameState.OnPlayerAdded.connect(_on_player_added)	
	GameState.OnPlayerUpdated.connect(_on_player_updated)	
	GameState.OnPlayerRemoved.connect(_on_player_removed)
		
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera.current = true
	
	for world in worlds:
		if world is String:
			worlds_list.add_item(world)
	pass
	
func _on_player_added(player_info: PlayerInfo):
	chat_overlay.sync_with_game_state()
	if not player_info.is_in_game:
		GameState.add_or_update_player_in_container(player_info, players_container)
	
func _on_player_updated(player_info: PlayerInfo):	
	chat_overlay.sync_with_game_state()	
	if not player_info.is_in_game:
		GameState.add_or_update_player_in_container(player_info, players_container)

func _on_player_removed(player_info: PlayerInfo):
	GameState.remove_player_from_container(player_info.peer_id, players_container)						
	chat_overlay.sync_with_game_state()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):	
	pass

@rpc("call_local", "any_peer")
func start_game(selected_world_index: int):	
	_on_world_list_item_selected(selected_world_index)
	
	var players = players_container.get_children()
	
	GameState.switch_to_scene(
		selected_world, 
		func(world: World):
			GameState.is_game_started = true
							
			for player_info in GameState.all_players_info:
				player_info.is_in_game = true				
				GameState.add_or_update_player_info.rpc(var_to_str(player_info))
	)

func _on_start_game_pressed():	
	var selected_items = worlds_list.get_selected_items()
	
	if selected_items.size() > 0:
		start_game.rpc(selected_items[0])
		
	pass


func _on_host_pressed():
	var port:int = host_port.text.to_int()
	var external_ip: String = NetworkState.create_server(port)

	GameState.add_chat_message("System", "Successfully hosting! on ip: "+ external_ip)
	
	chat_overlay.sync_with_game_state()
	
	host_join_container.hide()
	chat_overlay.show()
	world_selecter.show()
	

func _on_join_pressed():
	var port:int = join_port.text.to_int()	
	var external_ip: String = join_external_ip.text
	NetworkState.create_client(external_ip, port)
	
	chat_overlay.sync_with_game_state()

	world_selecter.show()	
	
	host_join_container.hide()
	chat_overlay.show()
	

func _on_world_list_item_selected(index):	
	var selected_list_item = worlds_list.get_item_text(index)
	selected_world = worlds[selected_list_item]
	pass	

func _on_character_selecter_pressed():	
	GameState.switch_to_character_selecter(players_container)
