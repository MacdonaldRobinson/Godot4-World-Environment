extends CharacterBody3D
class_name Player 

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_motion_state:Character.MotionState = Character.MotionState.standing
var enable_gravity: bool = true

@onready var currently_interacting_body: Interactable = null
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var floor_check: Area3D = $FloorCheck

@export var camera_controller: CameraController
@export var overlays: Overlays
@export var player_name: String

var character: Character
var pause_mode: bool = false

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority():
		return
	
func set_character(character: Character):
	
	for node in get_children():
		if node is Character:
			remove_child(node)
	
	self.add_child(character)
	self.character = character
	
	character.position = Vector3.ZERO
	character.rotation = Vector3.ZERO
	
	if not is_multiplayer_authority():
		return
	
	character.OnCharacterDying.connect(_on_character_on_character_dying)
	
func _physics_process(delta):
	if not is_multiplayer_authority():
		return
			
	if not character:
		return
		
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if Input.is_action_just_pressed("interact"):
		if currently_interacting_body:
			currently_interacting_body.interact(self)
			
		if character.is_sitting():
			collision_shape.disabled = false
			character.sit_to_stand()
	
	if character.pause_motion:
		return
		
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if character and is_on_floor_custom():
		character.set_motion.rpc(current_motion_state, Vector2(input_dir.x, -input_dir.y))
		
		if input_dir != Vector2.ZERO and camera_controller:
			rotation.y = camera_controller.rotation.y + deg_to_rad(180)
		
		var new_velocity = (character.animation_tree.get_root_motion_position() / delta).rotated(Vector3.UP, rotation.y);
		velocity = new_velocity

		
	if character.is_jumping() and character.is_foot_step:
		enable_gravity = true
		
	if enable_gravity:
		velocity.y = (velocity.y - gravity)
		
	# Add the gravity.		
	if character and not is_on_floor_custom() and not character.is_jumping():		
		character.falling()
		enable_gravity = true
		
	if Input.is_action_just_pressed("jump"):
		if character and is_on_floor_custom():
			enable_gravity = false
			character.jump.rpc()
			
	
	if Input.is_action_just_pressed("crouch_toggle"):
		if current_motion_state == Character.MotionState.standing:
			current_motion_state = Character.MotionState.crouching
		else:
			current_motion_state = Character.MotionState.standing
	
	
	move_and_slide()

func is_on_floor_custom():
	var bodies = floor_check.get_overlapping_bodies()
	
	if bodies.size() == 0:
		false
		
	for body in bodies:
		if not body is Player:
			return true
	
	return false

func _on_character_on_character_dying(character):
	#overlays.dead_overlay.show()
	pass


func _on_interact_area_body_entered(body):
	if not is_multiplayer_authority():
		return
			
	if body is Interactable:
		currently_interacting_body = body
		overlays.interact_overlay.show()


func _on_interact_area_body_exited(body):
	if not is_multiplayer_authority():
		return
			
	if overlays:
		currently_interacting_body = null
		overlays.interact_overlay.hide()


func _on_chair_on_interacting(chair: Interactable, interacting_body: Player):			
	var angle = interacting_body.global_rotation.angle_to(chair.interaction_point.global_rotation)
	interacting_body.global_rotation.y = angle
	interacting_body.global_position = chair.interaction_point.global_position
	
	interacting_body.global_position.y -= 0.2
	collision_shape.disabled = true
	
	interacting_body.character.sit();
