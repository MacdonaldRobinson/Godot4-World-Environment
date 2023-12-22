extends CanvasLayer
class_name Overlays

@onready var dead_overlay: DeadOverlay = $DeadOverlay
@onready var minmap_overlay: MiniMapOverlay = $MiniMapOverlay
@onready var interact_overlay: InteractOverly = $InteractOverly
@onready var message_overlay: MessageOverlay = $MessageOverlay

# Called when the node enters the scene tree for the first time.
func _ready():
	interact_overlay.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
