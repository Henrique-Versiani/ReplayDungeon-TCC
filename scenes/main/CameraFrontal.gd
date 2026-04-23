extends Camera3D
@onready var camera_ortogonal = $"../CameraOrtogonal"

var store_position = Vector3(-22,1,0.5)
var original_position: Vector3
var original_rotation: Vector3
var original_size: float

func _ready():
	original_position = position
	original_rotation = rotation
	original_size = size

func SwitchToPrincipal():
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($".", "position", camera_ortogonal.position, 0.5)
	tween.parallel().tween_property($".", "rotation", camera_ortogonal.rotation, 0.5)
	tween.parallel().tween_property($".", "size", camera_ortogonal.size, 0.5)
	await tween.finished
	current = false
	camera_ortogonal.current = true

func SwitchToStore():
	current = true
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($".", "position", Vector3(22.5,1,0.5), 0.5)
	tween.parallel().tween_property($".", "rotation", Vector3(deg_to_rad(-15), 0, 0), 0.5)
	tween.parallel().tween_property($".", "size", 4, 0.5)
	await tween.finished

func SwitchToOriginalPos():
	current = true
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($".", "position", original_position, 0.5)
	tween.parallel().tween_property($".", "rotation", original_rotation, 0.5)
	tween.parallel().tween_property($".", "size", original_size, 0.5)
	await tween.finished
