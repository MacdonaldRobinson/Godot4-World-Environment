extends CharacterBody3D
class_name Player

const SPEED = 5.0
const JUMP_VELOCITY = 4.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@export var current_motion_state:Character.MotionState = Character.MotionState.standing
var enable_gravity: bool = true

@onready var currently_interacting_body: Interactable = null
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var floor_check: Area3D = $FloorCheck
@onready var collect_item_sound: AudioStreamPlayer = %CollectItemSound
@onready var multiplayer_sync: MultiplayerSynchronizer = %MultiplayerSynchronizer

@export var camera_controller: CameraController
@export var overlays: Overlays
@export var player_name: String

@export var character: Character
var pause_mode: bool = false

func _ready():
	if not is_multiplayer_authority():
		return
		
func set_player_info(player_info: PlayerInfo):
	self.name = str(player_info.peer_id)
	self.set_multiplayer_authority(player_info.peer_id)
			
	if self.character:
		return
		
	var character: Character = ResourceLoader.load(player_info.character_scene_file_path).instantiate()
	character.character_name = player_info.character_name
	character.character_photo = player_info.character_photo

	set_character(character, player_info)
	
func set_character(character: Character, player_info: PlayerInfo):	
	for node in get_children():
		if node is Character:
			remove_child(node)
	
	self.add_child(character)
	self.character = character
	
	character.position = Vector3.ZERO
	character.rotation = Vector3.ZERO	
	
	character.set_player_info(player_info)
	
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
		
		if (input_dir != Vector2.ZERO and camera_controller) or ( camera_controller and camera_controller.is_aiming ):
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
			
	if character.is_weapon_pistol() and overlays:
		overlays.weapon_overlay.show()
		camera_controller.set_camera_aiming()
		
		var weapon: Weapon = character.get_weapon();
		
		if not weapon:
			return
			
		var weapon_inventory_item: InventoryItem = GameState.inventory.get_item(weapon)
		
		if Input.is_action_just_pressed("reload"):
			weapon.reload()
			
		if Input.is_action_just_pressed("shoot"):
			if not weapon.OnWeaponFired.is_connected(_on_weapon_fired):
				weapon.OnWeaponFired.connect(_on_weapon_fired)
				
			weapon.fire()	
			
	move_and_slide()
	
#	var player_info: PlayerInfo = GameState.get_player_info(self.name.to_int())
#	player_info.position = self.global_position
#
#	GameState.add_or_update_player_info(var_to_str(player_info))
	
	

func is_on_floor_custom():
	var bodies = floor_check.get_overlapping_bodies()
	
	if bodies.size() == 0:
		false
		
	for body in bodies:
		if not body is Player:
			return true
	
	return false
	
func _on_weapon_fired(weapon: Weapon):
	var camera_ray_cast: RayCast3D = camera_controller.get_camera_ray_cast()
	if camera_ray_cast.is_colliding():
		var collider = camera_ray_cast.get_collider()
		var collision_point = camera_ray_cast.get_collision_point()		
		
		weapon.play_hitpoint_effect(camera_ray_cast)
		
		if collider is Node:		
			var ammo: Ammo = weapon.ammo_scene.instantiate() as Ammo
			var ammo_decal_instance: AmmoDecal = ammo.ammo_decal_scene.instantiate() as AmmoDecal
			
			collider.add_child(ammo_decal_instance)
			
			ammo_decal_instance.global_position = camera_controller.camera_ray_cast.get_collision_point()
			ammo_decal_instance.look_at(camera_controller.camera_ray_cast.get_collision_normal())
			
			if collider is Player:
				var hit_player_info: PlayerInfo = GameState.get_player_info(collider.name.to_int())
				
				var hit_player: Player = collider as Player
				var hit_character: Character = hit_player.character as Character
				var current_health: int = hit_character.get_health()
				var new_health: int = current_health - 10
				
				if new_health < 0:
					new_health = 0
				
				hit_player_info.health = new_health
				hit_character.set_health.rpc(new_health)
				
				if new_health == 0:
					hit_player.current_motion_state = Character.MotionState.dying
					hit_player_info.character_motion_state = hit_player.current_motion_state
					
					hit_character.die.rpc()

				GameState.add_or_update_player_info.rpc(var_to_str(hit_player_info))
				
func _on_character_on_character_dying(character):
	#overlays.dead_overlay.show()
	pass


func _on_interact_area_body_entered(body):
	if not is_multiplayer_authority():
		return
			
	if body is Interactable:
		currently_interacting_body = body
		overlays.interact_overlay.show()
		
	if body is AutoCollectChildItem:
		var collectable_item: Collectable
		
		for child in body.get_children():
			if child is Collectable:
				collectable_item = child
				break
		
		if collectable_item and collectable_item is Collectable:
			GameState.inventory.add_or_update_item(collectable_item)
			collect_item_sound.play()
			
			overlays.screen_overlay.collected_item(collectable_item, collectable_item.quantity_on_collect)
			
			if collectable_item is Pistol:
				current_motion_state = Character.MotionState.weapon_pistol
				character.equip_weapon_pistol.rpc()
				var inventory_item: InventoryItem = GameState.inventory.get_item(collectable_item)
				
				if inventory_item:
					overlays.weapon_overlay.set_inventory_item(inventory_item)
					
			body.queue_free()


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
		
