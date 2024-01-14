extends Control
class_name Overlays

@onready var dead_overlay: DeadOverlay = $DeadOverlay
@onready var minmap_overlay: MiniMapOverlay = $MiniMapOverlay
@onready var interact_overlay: InteractOverly = $InteractOverly
@onready var message_overlay: MessageOverlay = $MessageOverlay
@onready var joystick_overlay: JoystickOverlay = $JoystickOverlay as JoystickOverlay
@onready var chat_overlay: ChatOverlay = $ChatOverlay

@export var camera_controller: CameraController
# Called when the node enters the scene tree for the first time.
func _ready():
	dead_overlay.hide()	
	minmap_overlay.hide()
	interact_overlay.hide()
	message_overlay.hide()
	chat_overlay.hide()
	
	joystick_overlay.camera_controller = camera_controller


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
