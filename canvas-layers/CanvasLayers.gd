extends CanvasLayer
class_name CanvasOverlays

@onready var dead_layer: DeadOverlay = $DeadOverlay as DeadOverlay
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func show_dead_layer():
	dead_layer.show_overlay()
	
