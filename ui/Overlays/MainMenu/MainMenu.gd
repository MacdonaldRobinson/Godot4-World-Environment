extends Control
class_name MainMenu

var character_selector_scene_path: String = "res://character-selector/CharacterSelector.tscn"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_quit_pressed():
	pass # Replace with function body.


func _on_character_selecter_pressed():
	GameState.switch_to_scene(character_selector_scene_path)