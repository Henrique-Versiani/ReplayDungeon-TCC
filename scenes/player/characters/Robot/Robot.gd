extends CharacterBody3D
class_name ROBOT

var complete: 			float = 100.0
var power_percentage: 	float = 0.0
var max_radius: 		float 
var min_radius: 		float = 0.5
var ability_reset_time: float = 0.01
var can_use_power: 	bool = false

enum PassiveLevel {
	LEVEL_1,
	LEVEL_2,
	LEVEL_3,
}

enum AbilityLevel {
	LEVEL_1,
	LEVEL_2,
	LEVEL_3,
}

var passive_level: PassiveLevel = PassiveLevel.LEVEL_1
var ability_level: AbilityLevel = AbilityLevel.LEVEL_1

func setPassiveLevel(new_level: PassiveLevel) -> void:
	passive_level = new_level

func getPassiveLevel() -> int:
	return passive_level
	
func setAbilityLevel(new_level: AbilityLevel) -> void:
	ability_level = new_level
	max_radius = JoyExplosion(ability_level)
	
func getAbilityLevel() -> int:
	return ability_level

func getAbilityResetTime() -> float:
	return ability_reset_time

func _ready():
	setPassiveLevel(PassiveLevel.LEVEL_3) 
	setAbilityLevel(AbilityLevel.LEVEL_3) 
	$AbilityArea3D/CollisionShape3D/MeshInstance3D.hide()
	
func MoreGoldPassive(level: int) -> float:
	var random_chance:float = randf()
	var multiplier = 1.0
	match level:
		PassiveLevel.LEVEL_1:
			if random_chance < 0.15:
				multiplier = 2.0 
		PassiveLevel.LEVEL_2:
			if random_chance < 0.35:
				multiplier = 2.0 
		PassiveLevel.LEVEL_3:
			if random_chance < 0.65:
				multiplier = 2.0
	return multiplier

func JoyExplosion(level: int) -> float:
	var radius:float = 8.0
	match level:
		AbilityLevel.LEVEL_1: radius =  8.0
		AbilityLevel.LEVEL_2: radius = 10.0
		AbilityLevel.LEVEL_3: radius = 12.0
	return radius

func ActiveAbility(level: int):
	if can_use_power:
		can_use_power = false
		$AbilityArea3D.monitoring = true
		$AbilityArea3D/AbilityCooldownTimer.start()
		$AbilityArea3D/CollisionShape3D/AnimationPlayer.play("shock_wave")
		ExpandeExplosionArea()
		ResetAbilityPercentage()
		
func ExpandeExplosionArea():
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($AbilityArea3D/CollisionShape3D, "shape:radius", max_radius , 0.25)
	await tween.finished
	
func _on_area_3d_area_entered(area):
	if area.has_method("Disable") and is_instance_of(area, TRAP):
		area.Disable()

func _on_ability_area_3d_area_exited(area):
	if area.has_method("Enable") and is_instance_of(area, TRAP):
		area.Enable()
		
func _on_ability_timer_timeout():
	$AbilityArea3D.monitoring = false
	$AbilityArea3D/CollisionShape3D.shape.radius = min_radius

func FillAbilityRadial(value: float) -> float:
	power_percentage += value * 2.5
	return power_percentage

func ResetAbilityPercentage() -> float:
	power_percentage *= 0.0
	return power_percentage
