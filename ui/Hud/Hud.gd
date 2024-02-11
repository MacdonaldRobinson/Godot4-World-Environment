extends Control
class_name Hud

@onready var photo: TextureRect = %Photo
@onready var character_name: Label = %Name
@onready var health_bar: CustomProgresBar = %HealthProgressBar


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if GameState.my_player:
		character_name.text = GameState.my_player.character.character_name
		health_bar.progress_bar.value = GameState.my_player.character.get_health()
		photo.texture = GameState.my_player.character.character_photo
