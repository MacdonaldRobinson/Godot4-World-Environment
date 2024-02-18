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
	var player_info: PlayerInfo = GameState.get_my_player_info()
	
	if player_info:		
		character_name.text = player_info.character_name
		health_bar.progress_bar.value = player_info.health
		photo.texture = player_info.character_photo
