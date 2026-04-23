extends Path3D
var model
var speed: float
var direction: int = 1
@export var loop_mode: int = 0

func _ready():
	speed = $"../Speed".speed
	for node in get_parent().get_children():
		if node is Area3D:
			model = node.duplicate()
			node.queue_free()
			$PathFollow3D.add_child(model)

func _process(delta):
	if loop_mode == 0:
		$PathFollow3D.progress += speed * delta * direction
	elif loop_mode == 1:
		if $Timer.time_left > 0: return
		$PathFollow3D.progress += speed * delta * direction
		if $PathFollow3D.progress_ratio == 1 or $PathFollow3D.progress_ratio == 0:
			Rotate180(direction)
			direction *= -1
			$Timer.start()
	else:
		print("ERROR!!! ASSIGN VALUE TO LOOP MODE")

func Rotate180(direction):
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(model, "rotation_degrees:y", model.rotation_degrees.y + 180 * direction, 0.5)
	await tween.finished

