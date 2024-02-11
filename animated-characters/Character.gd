extends Node3D
class_name Character

@onready var animation_tree:AnimationTree = $AnimationTree
@onready var foot_step_sound: AudioStreamPlayer3D = $FootStepSound
@onready var falling_timer: Timer = $FallingTimer
@onready var camera_lookat_point: Node3D = %CameraLookAtPoint
@onready var character_selector: Area3D = $CharacterSelector
@onready var character_name_label: Label3D = $Name
@onready var weapon_holder: Node3D = %WeaponHolder
@onready var head_look_at_point: Node3D = $HeadLookAtPoint
@onready var health_bar: HealthBar = %HealthBar as HealthBar

@export var character_name: String

var pause_motion:bool = false

var is_dead: bool = false
var is_foot_step = false

signal OnCharacterDying(character)
signal OnCharacterSelected(character)

enum MotionState{
	standing,
	crouching,
	falling,
	landing,
	sitting,
	sitting_to_standing,
	wave,
	weapon_pistol,
	dying
}

# Called when the node enters the scene tree for the first time.
func _ready():
	health_bar.hide()
	character_selector.input_event.connect(_on_character_selector_input_event)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not is_multiplayer_authority():
		return
	
	if character_name_label:
		character_name_label.text = character_name

	if weapon_holder and weapon_holder.get_child_count() > 0 and Input.is_action_just_pressed("shoot"):
		var item = weapon_holder.get_child(0)
		if item is Weapon:
			item.fire.rpc()
			
func set_health(health: int):
	health_bar.show()
	health_bar.custom_progress_bar.progres_bar.value = health
	
func get_health() -> int:
	return health_bar.custom_progress_bar.progres_bar.value
	
@rpc("call_local","any_peer")
func set_motion(motion_state: MotionState, blend_position:Vector2):
	falling_timer.stop()
	
	if pause_motion:
		return
	
	var str_motion_state:String = MotionState.find_key(motion_state)
	var motion_direction_path: String = "parameters/"+str_motion_state+"_motion_direction/blend_position";
		
	var current_motion_direction = animation_tree.get(motion_direction_path);
	var new_motion_direction: Vector2 
	
	if current_motion_direction is Vector2:
		var current_motion_state_index = animation_tree.get("parameters/motion_state/current_state");
		var current_motion_state:MotionState = MotionState.get(current_motion_state_index);
		
		new_motion_direction = lerp(current_motion_direction, blend_position, 0.1);
		animation_tree[motion_direction_path] = new_motion_direction
		
	animation_tree["parameters/motion_state/transition_request"] = str_motion_state
	

@rpc("call_local","any_peer")
func falling():
	if not is_dead and falling_timer.is_stopped():
		falling_timer.start()
		
	set_motion(MotionState.falling, Vector2(0, 0))
	
@rpc("call_local","any_peer")
func landing():
	set_motion(MotionState.landing, Vector2(0, 0))
	
@rpc("call_local","any_peer")
func sit():	
	pause_motion = true	
	set_motion(MotionState.sitting, Vector2(0, 0))
	
@rpc("call_local","any_peer")
func die():	
	if is_dead:
		return	
	set_motion(MotionState.dying, Vector2(0, 0))
	pause_motion = true	
	is_dead = true

@rpc("call_local","any_peer")
func sit_to_stand():	
	pause_motion = false
	set_motion(MotionState.sitting_to_standing, Vector2(0, 0))

@rpc("call_local","any_peer")
func wave():		
	pause_motion = false
	set_motion(MotionState.wave, Vector2(0, 0))
	
@rpc("call_local","any_peer")
func equip_weapon_pistol():
	var pistol: Pistol = preload("res://interactables/collectables/weapons/pistol/Pistol.tscn").instantiate()
	
	for node in weapon_holder.get_children():
		weapon_holder.remove_child(node)
	
	weapon_holder.add_child(pistol)	
	
	pause_motion = false
	set_motion(MotionState.weapon_pistol, Vector2(0, 0))

func is_sitting():
	return is_motion_state(MotionState.sitting)	
	
func is_dying():
	return is_motion_state(MotionState.dying)
	
func is_falling():
	return is_motion_state(MotionState.falling)	
	

func is_motion_state(motion_state: MotionState):
	var current_state = animation_tree["parameters/motion_state/current_state"];
	var str_motion_state:String = MotionState.find_key(motion_state)
	
	return current_state == str_motion_state
	
func is_weapon_pistol():
	return is_motion_state(MotionState.weapon_pistol)
	
func get_weapon() -> Weapon:
	if weapon_holder.get_child_count() > 0:
		return weapon_holder.get_child(0)
		
	return null
	
func is_jumping():	
	var is_jumping: bool = animation_tree["parameters/standing_jump/active"]
	return is_jumping	
	
@rpc("call_local","any_peer")
func jump():
	if is_jumping():
		return
	
	is_foot_step = false
	
	var current_motion_direction:Vector2 = animation_tree["parameters/standing_motion_direction/blend_position"];

	animation_tree["parameters/standing_jump_direction/blend_position"] = current_motion_direction
	animation_tree["parameters/standing_jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
	pass	

func foot_step():
	is_foot_step = true

func _on_falling_timer_timeout():
	is_dead = true
	emit_signal("OnCharacterDying", self)

func _on_character_selector_input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			wave()
			emit_signal("OnCharacterSelected", self)
		
