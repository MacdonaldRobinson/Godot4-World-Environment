extends Node3D
class_name World

@onready var players_container: Node3D = $PlayersContainer
@onready var camera_controller: CameraController = $CameraController
@onready var overlays: Overlays = $Overlays as Overlays

# Called when the node enters the scene tree for the first time.
func _ready():
	GameState.capture_mouse()
	
	for child in players_container.get_children():
		players_container.remove_child(child)	

#	var player: Player = GameState.get_my_player_in_container(players_container)
#
#	overlays.minmap_overlay.follow_node = player
#	overlays.minmap_overlay.show()
#	overlays.player_overlay.show()

	for player_info in GameState.all_players_info:
		add_or_update_player(player_info)

	GameState.OnPlayerAdded.connect(
		func(player_info: PlayerInfo):
			add_or_update_player(player_info)
	)

	GameState.OnPlayerUpdated.connect(
		func(player_info: PlayerInfo):
			add_or_update_player(player_info)
	)	

	GameState.OnPlayerRemoved.connect(
		func(player_info: PlayerInfo):
			remove_player(player_info)
	)	

func add_player(player: Player):
	player.reparent(players_container)
	
	var my_player_info: PlayerInfo = GameState.get_my_player_info()
	overlays.minmap_overlay.follow_node = player
	player.overlays = overlays

	overlays.chat_overlay.show()

	if player.name == str(my_player_info.peer_id):
		player.camera_controller = camera_controller
		camera_controller.camera_look_at_point = player.character.camera_lookat_point

func remove_player(player_info: PlayerInfo):
	overlays.chat_overlay.sync_with_game_state()	

	for existing_player in players_container.get_children():
		if existing_player.name == str(player_info.peer_id):
			players_container.remove_child(existing_player)
			overlays.chat_overlay.sync_with_game_state()
			return

func add_or_update_player(player_info: PlayerInfo):
	
	var player: Player = GameState.players_container.get_node(str(player_info.peer_id))	
	
	overlays.chat_overlay.sync_with_game_state()

	if not player: 
		player = GameState.add_or_update_player_in_container(player_info, players_container)
	else:
		player.reparent(players_container)
		player.set_multiplayer_authority(player_info.peer_id)

	var my_player_info: PlayerInfo = GameState.get_my_player_info()
	overlays.minmap_overlay.follow_node = player
	player.overlays = overlays

	overlays.chat_overlay.show()

	if player.name == str(my_player_info.peer_id):
		player.camera_controller = camera_controller
		camera_controller.camera_look_at_point = player.character.camera_lookat_point

func _input(event):
	if Input.is_action_just_pressed("mouse_capture_toggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			GameState.capture_mouse()
		else:
			GameState.release_mouse()
			
	if Input.is_action_just_pressed("main_menu"):
		var main_menu = overlays.main_menu_overlay as MainMenu
		
		if main_menu.visible == false:
			GameState.release_mouse()
			camera_controller.pause_rotation = true
			main_menu.show()
		else:
			GameState.capture_mouse()
			camera_controller.pause_rotation = false
			main_menu.hide()
