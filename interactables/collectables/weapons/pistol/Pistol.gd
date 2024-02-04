extends Weapon
class_name Pistol

@onready var spark: GPUParticles3D = $BarrelLock/Flash/Spark

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func interact(interacting_body):
	print("Pistol")

func shoot():
	spark.one_shot = true
	
