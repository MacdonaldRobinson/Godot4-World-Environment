extends Node3D
class_name World

@onready var players_container: Node3D = $PlayersContainer
@onready var player: Player = $PlayersContainer/Player as Player

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if Input.is_action_just_pressed("mouse_capture_toggle"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func set_player_character(character_scene: PackedScene):
	if character_scene:
		player.set_character(character_scene)
