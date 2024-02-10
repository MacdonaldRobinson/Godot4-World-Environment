extends Collectable
class_name Weapon

@export var has_ammo: bool
@export var ammo_max_capacity: int
@export var ammo_current_amount: int
@export var ammo_reload_amount: int
@export var ammo_scene: PackedScene

signal OnWeaponFired(weapon: Weapon)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func interact(interacting_body):
	print("Weapon")
	
func fire():
	OnWeaponFired.emit(self)
	print("emmited OnWeaponFired")
	
func reload():	
	var weapon_in_inventory: InventoryItem = GameState.inventory.get_item(self)
	var ammo_in_inventory:InventoryItem = GameState.inventory.get_item(ammo_scene.instantiate())
	
	if ammo_in_inventory and ammo_in_inventory.item_quantity > 0:
		var ammo: Ammo = ammo_in_inventory.item as Ammo
		
		var ammo_reload_amount = weapon_in_inventory.item.ammo_reload_amount
		
		if ammo_reload_amount > ammo_in_inventory.item_quantity:
			ammo_reload_amount = ammo_in_inventory.item_quantity
		
		if (weapon_in_inventory.item.ammo_current_amount + ammo_reload_amount) > weapon_in_inventory.item.ammo_max_capacity:
			ammo_reload_amount = weapon_in_inventory.item.ammo_max_capacity - weapon_in_inventory.item.ammo_current_amount

		weapon_in_inventory.item.ammo_current_amount += ammo_reload_amount
		ammo_in_inventory.item_quantity -= ammo_reload_amount
