extends SpringArm3D

@export var camera_look_at_point:Node3D
@onready var camera:Camera3D = $Camera3D

# Called when the node enters the scene tree for the first time.
func _ready():
	camera.look_at(camera_look_at_point.global_position)
	pass	
	
func _input(event):
	if !camera:
		return
		
	if event is InputEventMouseMotion:
		var x_strength = event.relative.x / 100;
		var y_strength = -event.relative.y / 200;
		
		rotate_y(x_strength)
		
		camera.rotate_x(y_strength)		
		#print()
		camera.rotation.x = clamp(camera.rotation.x, -0.5, 1)
		camera.rotation.y = 0
		camera.rotation.z = 0
		#camera.global_rotation.x = clamp(camera.global_rotation.x, 0, 0)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if camera_look_at_point:
		position = camera_look_at_point.global_position
