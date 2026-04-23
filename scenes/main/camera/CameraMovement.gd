extends Camera3D

@onready var player = $"../Player"
@export var move_speed: 					float = 3.0
@export var distance_forward_threshold:		float  = 4.5
@export var distance_sides_threshold:		float = 4.5
@export var distance_backward_threshold:	float =  4.5
var is_moving: bool = false
signal camera_is_moving 

func _process(delta):
	Move(delta)
	ShakeCamera()

func Move(delta):
	if is_moving: return
	#PEGA POSICAO DO PLAYER E DA CAMERA
	var player_pos: Vector3 = player.position
	var camera_pos: Vector3 = position
	
	#CALCULA DISTANCIA ENTRE O PLAYER E CAMERA NO EIXO X E Z
	var distance_z: int = round(abs(player_pos.z - camera_pos.z))
	var distance_x: int = round(abs(player_pos.x - camera_pos.x))
	
	is_moving = true
	
	#CASO ONDE O PLAYER ANDA PARA FRENTE 
	if distance_z >= distance_forward_threshold:
		camera_pos.z = lerp(camera_pos.z, player_pos.z + distance_forward_threshold, delta * move_speed)
		
	#CASO ONDE O PLAYER ANDA PARA TRÁS
	elif distance_z <= distance_backward_threshold:
		camera_pos.z = lerp(camera_pos.z, player_pos.z + distance_backward_threshold, delta * move_speed)
		
	#CASO ONDE O PLAYER ANDA PARA O LADO 
	if distance_x >= distance_sides_threshold:
		camera_pos.x = lerp(camera_pos.x, player_pos.x, delta * move_speed)
	#CASO ONDE O PLAYER ANDA PARA O LADO 
	else:
		camera_pos.x = lerp(camera_pos.x, player_pos.x, delta * move_speed)
	
	#NOVA POSICAO DA CAMERA
	position = camera_pos
	is_moving = false

func ShakeCamera():
	h_offset = randf_range(0, player.trauma_value )
	v_offset = randf_range(0, player.trauma_value )

func ResetCamera():
	position = Vector3(22.5,8.5,3.5)
