extends Node3D
class_name World

@onready var players_container: Node3D = $PlayersContainer
@onready var camera_controller: CameraController = $CameraController
@onready var overlays: Overlays = $Overlays

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func remove_player(peer_id: int):
	var my_player: Player = players_container.get_node(str(multiplayer.get_unique_id())) as Player
	var found_player: Player = players_container.get_node(str(peer_id)) as Player
	
	if found_player and my_player:
		players_container.remove_child(found_player)
		overlays.chat_overlay.set_players(players_container.get_children(), my_player)	
	
	
func set_players(players: Array[Node], my_player: Player):
	for node in players_container.get_children():
		players_container.remove_child(node)
	
	for player in players:
		if player is Player:
			var old_position = player.position
			var old_rotation = player.rotation
			
			player.reparent(players_container)
			
			player.position = old_position
			player.rotation = old_rotation
						
			overlays.chat_overlay.set_players(players, my_player)		
			player.overlays = overlays
		
		overlays.chat_overlay.show()
		
		if player.name == my_player.name:
			player.camera_controller = camera_controller		
			camera_controller.camera_look_at_point = player.character.camera_lookat_point
		

func _input(event):
	if Input.is_action_just_pressed("mouse_capture_toggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
