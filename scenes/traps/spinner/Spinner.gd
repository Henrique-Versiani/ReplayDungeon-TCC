extends TRAP

const ROTATION_SPEED: 	float = 0.1
const SPIN_INTERVAL: 	float = 2.25

var trap_state: TrapState = TrapState.active

var spin_timer: float = 0
var previous_raycast_rotation: float = 0 
var rotation_dest: float = 0.0

func _ready():
	previous_raycast_rotation = GetCurrentRotationDeg()
	#SpinHitboxes()
	#CalculateRotation(previous_raycast_rotation)
	#spin_timer = 0
	PerformSpin()
	UpdateRotation()

func _process(delta):
	if trap_state == TrapState.disabled: return
	UpdateSpinTimer(delta)
	if ShouldSpin(): PerformSpin()
	UpdateRotation()
		
func ShouldSpin() -> bool:
	return spin_timer >= SPIN_INTERVAL
	
func GetCurrentRotationDeg() -> float:
	return ceil(rad_to_deg($"spinner-double".rotation.y))

func UpdateSpinTimer(delta):
	spin_timer += delta
	
func PerformSpin():
	SpinHitboxes()
	rotation_dest = CalculateRotation(GetCurrentRotationDeg())
	ResetSpinTimer()

func ResetSpinTimer():
	spin_timer = 0.0
	
func UpdateRotation():
	if(spin_timer < 1):
		$"spinner-double".rotation.y = lerp_angle($"spinner-double".rotation.y, deg_to_rad(rotation_dest), ROTATION_SPEED)
	
func CalculateRotation(current_rotation) -> float:
	if current_rotation == 360: $"spinner-double".rotation.y = 0
	var next_rotation = round(90 + rad_to_deg($"spinner-double".rotation.y))
	return next_rotation

func SpinHitboxes():
	var initial_spinner_position = $"spinner-double".rotation.y
	var target_y =  floor(rad_to_deg(initial_spinner_position)) + rad_to_deg(PI/2)
	previous_raycast_rotation = floor(rad_to_deg(initial_spinner_position))
	SpinAnimation(target_y)
	
func SpinAnimation(target_angle_y):
	var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.parallel().tween_property($Area3D/CollisionShape3D,   "rotation:y", deg_to_rad(target_angle_y), ROTATION_SPEED)
	tween.parallel().tween_property($CollisionShape3D2,  	 	"rotation:y", deg_to_rad(target_angle_y), ROTATION_SPEED)
	tween.parallel().tween_property($"spinner-double",   		"rotation:y", deg_to_rad(target_angle_y), ROTATION_SPEED)
	tween.parallel().tween_property($RayCast3D, 		 		"rotation:y", deg_to_rad(target_angle_y), ROTATION_SPEED)
	tween.parallel().tween_property($RayCast3D2, 		 		"rotation:y", deg_to_rad(target_angle_y), ROTATION_SPEED)
	await tween.finished


func TransformVector3ToVector2(dir: Vector3) -> Vector2:
	return Vector2(dir.x, dir.z)

func _on_area_3d_body_entered(body):
	if previous_raycast_rotation:
		var current_ray_cast_rotation= $RayCast3D.rotation.y
		#SENTIDO HORARIO e PLAYER ABAXIO DO MEIO DO SPINNER
		if current_ray_cast_rotation < previous_raycast_rotation and abs(position.z) > abs(body.position.z):
			body.Move(Vector2.RIGHT * 3, true)
		#SENTIDO HORARIO e PLAYER ACIMA DO MEIO DO SPINNER
		elif current_ray_cast_rotation < previous_raycast_rotation and abs(position.z) < abs(body.position.z):
			body.Move(Vector2.LEFT * 3, true)
		elif current_ray_cast_rotation < previous_raycast_rotation and abs(position.z) == abs(body.position.z) and abs(position.x) > abs(body.position.x):
			body.Move(Vector2.DOWN * 3, true)
		elif current_ray_cast_rotation < previous_raycast_rotation and abs(position.z) == abs(body.position.z) and abs(position.x) < abs(body.position.x):
			body.Move(Vector2.UP * 3, true)
