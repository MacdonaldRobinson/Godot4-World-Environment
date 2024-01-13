extends Node3D
class_name Character

@onready var animation_tree:AnimationTree = $AnimationTree
@onready var foot_step_sound: AudioStreamPlayer3D = $FootStepSound
@onready var falling_timer: Timer = $FallingTimer
@onready var camera_lookat_point: Node3D = $CameraLookAtPoint
@onready var character_selector: Area3D = $CharacterSelector

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
	wave
}

# Called when the node enters the scene tree for the first time.
func _ready():
	character_selector.input_event.connect(_on_character_selector_input_event)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func set_motion(motion_state: MotionState, blend_position:Vector2):
	falling_timer.stop()
	
	if pause_motion:
		return
	
	var str_motion_state:String = MotionState.find_key(motion_state)
		
	var current_motion_direction:Vector2 = animation_tree["parameters/"+str_motion_state+"_motion_direction/blend_position"];
	var new_motion_direction: Vector2 = lerp(current_motion_direction, blend_position, 0.1);
	var current_motion_state:MotionState = MotionState.get(animation_tree["parameters/motion_state/current_state"]);
	
	animation_tree["parameters/motion_state/transition_request"] = str_motion_state
	
	if motion_state == MotionState.standing:
		animation_tree["parameters/standing_motion_direction/blend_position"] = new_motion_direction
	elif motion_state == MotionState.crouching:
		animation_tree["parameters/crouching_motion_direction/blend_position"] = new_motion_direction		
	pass

func falling():
	if not is_dead and falling_timer.is_stopped():
		falling_timer.start()
		
	animation_tree["parameters/motion_state/transition_request"] = "falling"	
	
func landing():
	animation_tree["parameters/motion_state/transition_request"] = "landing"
	
func sit():	
	pause_motion = true
	animation_tree["parameters/motion_state/transition_request"] = "sitting"	

func sit_to_stand():	
	pause_motion = false
	animation_tree["parameters/motion_state/transition_request"] = "sitting_to_standing"	

func wave():	
	pause_motion = false
	animation_tree["parameters/motion_state/transition_request"] = "wave"

func is_sitting():
	var current_state = animation_tree["parameters/motion_state/current_state"];
	return current_state == "sitting"	
	
func is_falling():
	var current_state = animation_tree["parameters/motion_state/current_state"];
	return current_state == "falling"	
	
func is_jumping():	
	var is_jumping: bool = animation_tree["parameters/standing_jump/active"]
	return is_jumping	
	
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
		
