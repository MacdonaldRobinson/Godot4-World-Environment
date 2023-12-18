extends SpringArm3D
class_name CameraController

@export var camera_look_at_point:Node3D

@onready var camera:Camera3D = $Camera3D
@onready var camera_ray_cast: RayCast3D = $CameraRayCast as RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready():	
	position = camera_look_at_point.global_position
	pass	
	
func get_camera_ray_cast() -> RayCast3D:
	return camera_ray_cast
	
func _input(event):
	if !camera:
		return
		
	if event is InputEventMouseMotion:
		var x_strength = -event.relative.x / 200;
		var y_strength = -event.relative.y / 200;
		
		rotate_y(x_strength)
		
		camera.rotate_x(y_strength)		
		camera.rotation.x = clamp(camera.rotation.x, -0.5, 1)
		camera.rotation.y = 0
		camera.rotation.z = 0
		
	if event is InputEventMouseButton:
		if event.button_index == 4:
			if spring_length > 1:
				spring_length -= 0.1
		elif event.button_index == 5:
			if spring_length < 10:
				spring_length += 0.1

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if camera_look_at_point:		
		position = lerp(position, camera_look_at_point.global_position, 0.1)
