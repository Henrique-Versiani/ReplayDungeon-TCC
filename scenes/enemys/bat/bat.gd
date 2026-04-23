extends ENEMY
var initial_y: int
var speed: float = 1.5
@onready var ray_cast_3d = $BatModel/RayCastControl/RayCast3D
@onready var ray_cast_3_left = $BatModel/RayCastControl/RayCast3Left
@onready var ray_cast_3_right = $BatModel/RayCastControl/RayCast3Right

func _on_bat_model_body_entered(body):
	ENEMY.KillPlayer(body)



