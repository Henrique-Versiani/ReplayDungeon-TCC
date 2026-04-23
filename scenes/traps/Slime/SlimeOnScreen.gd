extends CanvasLayer

@onready var splash = $MarginContainer/Control/Splash
@onready var splash_2 = $MarginContainer/Control/Splash2
@onready var splash_3 = $MarginContainer/Control/Splash3
@onready var splash_4 = $MarginContainer/Control/Splash4

var random_positions = []

func ChooseRandomSpot() -> Vector2:
	var _x: float = randf_range(0, 202)
	var _y: float = randf_range(0, 448)
	
	return Vector2(_x, _y)

func AssingSplashPositions():
	for x in range (0,4):
		random_positions.append(ChooseRandomSpot())
	$AnimationPlayer.play("splash")
	$Timer.start()
	splash.position = random_positions[0]
	splash_2.position = random_positions[1]
	splash_3.position = random_positions[2]
	splash_4.position = random_positions[3]

func _on_timer_timeout():
	$AnimationPlayer.play("unsplash")
