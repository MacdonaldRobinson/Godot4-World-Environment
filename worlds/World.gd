extends Node3D
class_name World

@onready var players_container: Node3D = $PlayersContainer
@onready var camera_controller: CameraController = $CameraController
@onready var overlays: Overlays = $Overlays as Overlays

# Called when the node enters the scene tree for the first time.
func _ready():
	GameState.capture_mouse()
	overlays.minmap_overlay.follow_node = GameState.my_player
	overlays.minmap_overlay.show()
	overlays.player_overlay.show()
		
	GameState.OnPlayerAdded.connect(
		func(player_info: PlayerInfo):
			overlays.chat_overlay.sync_with_game_state()
			add_player(player_info)
	)
	
	GameState.OnPlayerUpdated.connect(
		func(player_info: PlayerInfo):
			print("Player Updated: ", var_to_str(player_info))
	)	
	
	GameState.OnPlayerRemoved.connect(
		func(player_info: PlayerInfo):
			overlays.chat_overlay.sync_with_game_state()
			remove_player(player_info)
	)	
	
func remove_player(player_info: PlayerInfo):
	for existing_player in players_container.get_children():
		if existing_player.name == str(player_info.peer_id):
			players_container.remove_child(existing_player)
			return	
	
func add_player(player_info: PlayerInfo):
	for existing_player in players_container.get_children():
		if existing_player.name == str(player_info.peer_id):
			return
	
	var player: Player = GameState.player_scene.instantiate();
	player.name = str(player_info.peer_id)
	
	var character: Character = ResourceLoader.load(player_info.character_scene_file_path).instantiate()
	character.character_name = player_info.character_name
	
	player.set_character(character)		
	players_container.add_child(player)

	player.set_multiplayer_authority(player.name.to_int())
		
	character.set_health(player_info.health)
	overlays.minmap_overlay.follow_node = player
	player.overlays = overlays
	
	overlays.chat_overlay.sync_with_game_state()	
	overlays.chat_overlay.show()
	
	if player.name == GameState.my_player.name:
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
			GameState.stop_my_player_process()
			GameState.release_mouse()
			camera_controller.pause_rotation = true
			main_menu.show()
		else:
			GameState.start_my_player_process()
			GameState.capture_mouse()
			camera_controller.pause_rotation = false
			main_menu.hide()
