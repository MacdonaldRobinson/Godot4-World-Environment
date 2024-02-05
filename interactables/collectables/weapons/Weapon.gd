extends Collectable
class_name Weapon

@export var has_ammo: bool
@export var max_ammo_capacity: int
@export var current_ammo_amount: int
@export var ammo_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func interact(interacting_body):
	print("Weapon")
	
func fire():
	print("Weapon fired")
