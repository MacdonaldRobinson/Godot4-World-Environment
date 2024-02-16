extends World
class_name WorldTwo

@onready var drop_timer: Timer = $DropTimer
@onready var drop_zone: Area3D = $DropZone
@onready var auto_collectable_item_scene: PackedScene = preload("res://interactables/AutoCollectChildItem/AutoCollectChildItem.tscn")

func _on_drop_timer_timeout():
	if multiplayer.is_server():
		var drop_item: AutoCollectChildItem = auto_collectable_item_scene.instantiate()
		var ammo: Ammo = preload("res://interactables/collectables/weapons/pistol/PistolAmmo/PistolAmmo.tscn").instantiate()
		ammo.quantity_on_collect = 20
		drop_item.add_child(ammo)
		
		drop_zone.add_child(drop_item)
	
	
