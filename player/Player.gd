extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_motion_state:Character.MotionState = Character.MotionState.standing

@onready var floor_ray_cast: RayCast3D = $FloorRayCast as RayCast3D
@onready var character: Character = $Clara as Character
@export var camera_controller: CameraController

func _physics_process(delta):

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if character:
		character.set_motion(current_motion_state, Vector2(input_dir.x, -input_dir.y))
		rotation.y = camera_controller.rotation.y + deg_to_rad(180)
		velocity = (character.animation_tree.get_root_motion_position() / delta).rotated(Vector3.UP, rotation.y)
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= (gravity*100) * delta
		
		if character and not floor_ray_cast.is_colliding():
			character.falling()
		
	if Input.is_action_just_pressed("jump"):
		character.jump()
	
	if Input.is_action_just_pressed("crouch_toggle"):
		if current_motion_state == Character.MotionState.standing:
			current_motion_state = Character.MotionState.crouching
		else:
			current_motion_state = Character.MotionState.standing

	move_and_slide()
