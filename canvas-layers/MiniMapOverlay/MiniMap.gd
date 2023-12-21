extends Control
class_name MiniMapOverlay

@export var follow_node: Node3D

@onready var camera: Camera3D = %MiniMapCam
# Called when the node enters the scene tree for the first time.
func _ready():
	camera.position = follow_node.position
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if camera:
		camera.position.x = follow_node.position.x
		camera.position.z = follow_node.position.z
