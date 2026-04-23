extends StaticBody3D
class_name GOLEM

var temp_body
const FALL_ANIM_DURATION:	  float = 2.5
var hit_count: int = 2
var is_falling: bool

func _process(_delta):
	if get_parent().get_cell_item(Vector3(position.x, position.y, position.z - 1)) == -1 and !is_falling: FallAnimation()
	if $RayCastFront.is_colliding():
		if !temp_body: temp_body = $RayCastFront.get_collider()
	if $RayCastBack.is_colliding():
		if !temp_body: temp_body = $RayCastBack.get_collider()


func Move(direction: Vector2) -> Vector3:
	
	if !CheckRaycastCollision(direction):
		var target_position: Vector3 = position + TransformVector2ToVector3(direction)
		var next_position_values: Array = get_parent().CheckNextPlayerPosition(target_position)
		var verify_fall: float = next_position_values[0]
		var mesh_index = next_position_values[1]
		
		if !verify_fall or mesh_index == -1: FallAnimation()
		if Settings.enable_sound: $GolemSFX.play()
		var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
		tween.tween_property($".", "position", target_position, 0.50)
		await tween.finished
		
		return target_position
	return position
	
func CheckRaycastCollision(direction: Vector2) -> bool:
	if direction == Vector2.UP:
		return $RayCastBack.is_colliding()
	elif direction == Vector2.DOWN:
		return $RayCastFront.is_colliding()
	elif direction == Vector2.LEFT:
		return $RayCastLeft.is_colliding()
	elif direction == Vector2.RIGHT:
		return $RayCastRight.is_colliding()
	return false
	
func TransformVector2ToVector3(direction: Vector2) -> Vector3:
	return Vector3(direction.x, 0, direction.y )

func FallAnimation():
	if is_falling: return
	is_falling = true
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "position:y", self.position.y - 20, FALL_ANIM_DURATION)
	await tween.finished
	is_falling = false
	queue_free()
	
func GetHitCount() -> int:
	return hit_count

func DestroyGolem() -> void:
	#APAGAR NO GRIDMAP
	queue_free()
