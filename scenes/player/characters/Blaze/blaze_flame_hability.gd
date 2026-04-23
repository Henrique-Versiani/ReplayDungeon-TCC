extends Area3D
enum {active, disable}
var ability_state
var flamefury_failsafe

func _ready():
	$".".hide()
	ability_state = false
	$CollisionPolygon3D.disabled = true
	monitoring = false
	flamefury_failsafe = false

func StartFlameFury():
	$"../AbilityTimer".start()
	$".".show()
	ability_state = true
	$CollisionPolygon3D.disabled = false
	monitoring = true
	flamefury_failsafe = true
	
func _on_area_entered(area):
	if ability_state == true:
		var super_parent_instance = FindFinalParent(area)
		if is_instance_of(super_parent_instance, ENEMY):
			super_parent_instance.queue_free()

func FindFinalParent(node):
	if node.get_parent() == null:
		return node
	elif is_instance_of(node, ENEMY):
		return node
	else:
		return FindFinalParent(node.get_parent())

func _on_ability_timer_timeout():
	$".".hide()
	$CollisionPolygon3D.disabled = true
	monitoring = false
	$"..".can_use_power = false
	if flamefury_failsafe: 
		$"..".StartAbilityCooldownTimer()
		flamefury_failsafe = false
