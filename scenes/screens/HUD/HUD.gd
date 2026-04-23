extends CanvasLayer
signal  use_power
signal 	power_up

var is_power_up: 	   bool = false
var power_failsafe:	bool = false
var current_distance:  int = 0

func _ready():
	_on_player_update_highscore()
	$"../Player".connect("power_percentage_update", UpdatePowerPercentageRadial)
	$"../Player".connect("coin_collected", _on_player_coin_collected)
	$"../Player".connect("update_distance", _on_player_update_distance)
	$"../Player".connect("update_highscore", _on_player_update_highscore)
	
func _on_player_coin_collected(coins) -> void:
	$MarginContainerCoin/Control/Plus/Coins.text = str(coins)

func _on_player_update_distance(distance) -> void:
	if current_distance < distance:
		$MarginContainerDistance/Control/Distance.text = str(distance) + "m"
		$"../ScreensManager/GameOverScreen/MarginContainer/VBoxContainer/Panel/HBoxContainer/Control3/DistanceInfoLabel".text = "Distância Percorrida: " + str(distance) + " m"

func _on_player_update_highscore():
	$MarginContainerDistance/Control/HighScore.text = str("	Best: " + str(Settings.LoadHighScore()) +"m")

func _process(delta):
	if $MarginContainer/Power/PowerPercentage.material.get_shader_parameter("value") < 0.5:
		power_failsafe =  false
	if $MarginContainer/Power/PowerPercentage.material.get_shader_parameter("value") >= 0.99 and power_failsafe == false and !is_power_up:
		is_power_up = true
		power_failsafe = true
		power_up.emit()
		
func _on_power_pressed() -> void:
	if is_power_up:
		print("power up")
		is_power_up = false
		use_power.emit()
		
func UpdatePowerPercentageRadial(new_percentage: float) -> void:
	var tween:Tween = get_tree().create_tween()
	tween.tween_method(set_shader_value, $MarginContainer/Power/PowerPercentage.material.get_shader_parameter("value"), new_percentage/100, 0.25);  

func set_shader_value(value: float) -> void:
	$MarginContainer/Power/PowerPercentage.material.set_shader_parameter("value", value)

func ResetPowerPercentageRadial(reset_time: float) -> void:
	var tween:Tween = get_tree().create_tween()
	tween.tween_method(set_shader_value, $MarginContainer/Power/PowerPercentage.material.get_shader_parameter("value"), 0.0, reset_time);  
func ResetPlayerHabilities():
	ResetPowerPercentageRadial(0.0)
