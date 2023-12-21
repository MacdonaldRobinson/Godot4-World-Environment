extends CanvasLayer
class_name CanvasOverlays

@onready var dead_overlay: DeadOverlay = $DeadOverlay as DeadOverlay
@onready var minmap_overlay: MiniMapOverlay = $MiniMapOverlay as MiniMapOverlay
@onready var interact_overlay: InteractOverly = $InteractOverly as InteractOverly

# Called when the node enters the scene tree for the first time.
func _ready():
	interact_overlay.hide()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
