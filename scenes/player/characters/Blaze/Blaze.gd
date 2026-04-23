extends CharacterBody3D
class_name BLAZE

var complete: 		  float = 99.9
var power_percentage: float = 0.0
var ability_reset_time: float = 10.0
var can_use_power: bool = false
signal start_ability_timer

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
	
func getAbilityLevel() -> int:
	return ability_level

func getAbilityResetTime() -> float:
	return ability_reset_time
	
func _ready():
	get_parent().connect("player_moved_first_time", StartAbilityCooldownTimer)
	setPassiveLevel(PassiveLevel.LEVEL_3) 
	setAbilityLevel(AbilityLevel.LEVEL_3)
	setFlameFuryTimer(getAbilityLevel())

func ActiveAbility(level: int):
	if can_use_power:
		$FlameFury.StartFlameFury()
		
func PassCobWeb(level: int) -> int:
	var skip_value:int
	match level:
		PassiveLevel.LEVEL_1:
			skip_value = 1
		PassiveLevel.LEVEL_2:
			skip_value = 2
		PassiveLevel.LEVEL_3:
			skip_value =  4
	return skip_value

func FlamesFury(level: int) -> float:
	return 0.0
	
func setFlameFuryTimer(level: int) -> void:
	var ability_time: float = 3.5
	match level:
		PassiveLevel.LEVEL_1:
			ability_time = 3.5
		PassiveLevel.LEVEL_2:
			ability_time = 5.5
		PassiveLevel.LEVEL_3:
			ability_time =  8.5
	$AbilityTimer.wait_time = ability_time

func FillAbilityRadial() -> float:
	if $AbilityCooldown.is_stopped() or can_use_power: 
		return power_percentage
	power_percentage = abs($AbilityCooldown.time_left - $AbilityCooldown.wait_time) * 10
	return power_percentage

func StartAbilityCooldownTimer():
	$AbilityCooldown.start()

func _on_ability_timer_timeout():
	$AbilityCooldown.stop()

func ResetAbilityPercentage() -> void:
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property($".", "power_percentage", 0.0, $AbilityTimer.wait_time)
