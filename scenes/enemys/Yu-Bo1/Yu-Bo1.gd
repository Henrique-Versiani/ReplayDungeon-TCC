extends CharacterBody3D
@onready var Yu_bo1 = $"."
@onready var grid_map = $"../GridMap"
var player_group: String = "player"
var can_move: bool = true
var is_moving: bool = false
var is_falling: bool = false

func _on_collision_body_entered(body):
	if body.is_in_group("player") and !body.player_died:
		body.Die()

func _on_activation_area_body_entered(body):
	pass # Replace with function body.

func _process(delta):
	if get_parent().get_cell_item(Vector3(position.x, position.y, position.z - 1)) == -1 and !is_falling:
		Fall()
		
func _input(_event):
	if is_moving or is_falling or !can_move: return
	if Input.is_action_pressed("up"):
		move_yu_bo1(TransformVector2ToVector3(Vector2.DOWN))
	elif Input.is_action_pressed("down"):
		move_yu_bo1(TransformVector2ToVector3(Vector2.UP))
	elif Input.is_action_pressed("left"):
		move_yu_bo1(TransformVector2ToVector3(Vector2.LEFT))
	elif Input.is_action_pressed("right"):
		move_yu_bo1(TransformVector2ToVector3(Vector2.RIGHT))
		
func move_yu_bo1(direction: Vector3):
	can_move = false
	var target_position: Vector3 = Yu_bo1.transform.origin + direction 
	rotation_degrees.y = GetAngleToDirection(Vector2(direction.x, direction.z))
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($".", "position", target_position, 0.2)
	await tween.finished
	can_move = true

func GetAngleToDirection(direction: Vector2) -> float:
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

func TransformVector2ToVector3(direction: Vector2) -> Vector3:
	return Vector3(direction.x, 0, direction.y)
	
func Fall() -> void:
	is_falling = true
	await FallAnimation()
	is_falling = false

func FallAnimation():
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	var rotation_position: Vector3 = Vector3(deg_to_rad(-90), deg_to_rad(180), deg_to_rad(-90))
	tween.parallel().tween_property(Yu_bo1, "position:y", Yu_bo1.position.y - 25, 1.5)
	tween.parallel().tween_property(Yu_bo1, "rotation", rotation_position, 1.5)
	await tween.finished
	Yu_bo1.free()
