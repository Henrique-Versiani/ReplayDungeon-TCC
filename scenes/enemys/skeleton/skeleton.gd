extends ENEMY
@onready var grid_map = $"../GridMap"
@onready var animation_player = $Skeleton_Warrior/AnimationPlayer
@onready var skeleton = $"."
enum {active, idle}
var player_group: String = "player"
var on: bool = false
var is_moving: bool = false
var is_falling: bool = false
var turn
var temp_body
func _ready():
	animation_player.play("Death_C_Pose")
	
func _process(delta):
	if get_parent().get_cell_item(Vector3(position.x, position.y, position.z - 1)) == -1 and !is_falling:
		Fall()

func _on_collision_body_entered(body):
	var animation_attack_dir: Dictionary = {0:"Unarmed_Melee_Attack_Kick", 1:"Unarmed_Melee_Attack_Punch_A", 2:"Unarmed_Melee_Attack_Punch_B"}
	var random_num: int = randi()%3
	animation_player.play(animation_attack_dir[random_num])
	
	ENEMY.KillPlayer(body)

func _on_activation_area_body_entered(body):
	animation_player.play("Death_C_Skeletons_Resurrect")
	turn = active
	temp_body = body
	$Timer.start()

func _on_activation_area_body_exited(body):

	turn = idle
	temp_body = null
	animation_player.play_backwards("Death_C_Skeletons_Resurrect")
	
func skeleton_turn(body):
	if self.position.x > body.position.x:
		#print("move skl left")
		move_skeleton(Vector3.LEFT)
	elif skeleton.position.x < body.position.x:
		#print("move skl right")
		move_skeleton(Vector3.RIGHT)
	elif skeleton.position.z > body.position.z:
		#print("move skl up")
		move_skeleton(Vector3.FORWARD)
	elif skeleton.position.z < body.position.z:  
		#print("move skl down")
		move_skeleton(Vector3.BACK)
		
func move_skeleton(direction: Vector3):
	var target_position: Vector3 = skeleton.transform.origin + direction
	self.rotation_degrees.y = GetAngleToDirection(Vector2(direction.x, direction.z))
	if $RayCast3D.is_colliding() and $RayCast3D.get_collider() != null and $RayCast3D.get_collider().is_in_group(player_group):
		var animation_attack_dir: Dictionary = {0:"Unarmed_Melee_Attack_Kick", 1:"Unarmed_Melee_Attack_Punch_A", 2:"Unarmed_Melee_Attack_Punch_B"}
		var random_num: int = randi()%3
		animation_player.play(animation_attack_dir[random_num])
	else:
		animation_player.play("Jump_Full_Long")
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($".", "position", target_position, 0.35)
	await tween.finished

func GetAngleToDirection(direction: Vector2) -> float:
	"""
	PEGA A ROTACAO A PARTIR DA DIRECAO, FUNCIONA mas da pra melhorar isso aqui!
	"""
	if direction.y == -1:
		return 180
	elif direction.y == 1:
		return 0
	elif direction.x == -1:
		return -90
	elif direction.x == 1:
		return 90
	else:
		return 0

func ChangeAnimationSpped(speed: float):
	animation_player.speed_scale = speed
	
func _on_timer_timeout():

	if turn == active:
		skeleton_turn(temp_body)

func Fall() -> void:
	is_falling = true
	await FallAnimation()
	is_falling = false

func FallAnimation():
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	var rotation_position: Vector3 = Vector3(deg_to_rad(-90), deg_to_rad(180), deg_to_rad(-90))
	tween.parallel().tween_property(skeleton, "position:y", skeleton.position.y - 25, 1.5)
	tween.parallel().tween_property(skeleton, "rotation", rotation_position, 1.5)
	await tween.finished
	skeleton.free()
