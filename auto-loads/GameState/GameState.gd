extends Node

var my_player: Player
var is_game_started: bool = false
var inventory: Inventory = Inventory.new() as Inventory

@onready var player_container: Node3D = %PlayerContainer
@onready var scene_loader: Control = %SceneLoader

func _ready():
	player_container.hide()
	scene_loader.hide()
	
	my_player = preload("res://player/Player.tscn").instantiate() as Player
	player_container.add_child(my_player)	
	
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

func move_my_player_to_container(container_node: Node3D, reset_position_to_zero: bool = false):
	GameState.my_player.reparent(container_node)
	start_my_player_process()
	
	if reset_position_to_zero:
		reset_my_player_position_to_zero()	

func move_my_player_to_gamestate(reset_position_to_zero: bool = true):
	stop_my_player_process()
	
	GameState.my_player.reparent(GameState.player_container)
	
	if reset_position_to_zero:
		reset_my_player_position_to_zero()

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

func get_current_scene() -> Node3D:
	for scene in get_tree().root.get_children():
		if scene is Node3D:
			return scene
			
	return null
	
func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)	
			
func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)	
	
