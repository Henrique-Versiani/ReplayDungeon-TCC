extends TRAP

var trap_state: TrapState = TrapState.active

var move_speed: 	float = randf_range(1.0, 2.5)
var rotation_speed: float = 5.0
var x_range:		float = 2
var direction:		int = 1
var initial_pos:	Vector2
	
func _process(delta):
	"""
	GIRA A SERRA E INTERPOLA A POSICAO DELA ATE O RANGE (X) E DEPOIS INVERTE A DIRECAO DO MOVIMENTO
	"""
	if trap_state == TrapState.active: 
		$Center.rotation.z += rotation_speed * delta
		$Center.position.x += move_speed * delta * direction
	if abs($Center.position.x) > abs(initial_pos.x + x_range):
		direction *= -1
	$CollisionShape3D.position = $Center.position

func _on_body_entered(body):
	if trap_state == TrapState.active:
		TRAP.KillPlayer(body)
		
func Disable():
	trap_state = TRAP.ForceDisabledMode()
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($".", "position:y", position.y - 0.25, 0.5)
	await tween.finished

func Enable():
	trap_state = TRAP.ForceEnabledMode()
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($".", "position:y", position.y + 0.25, 0.5)
	await tween.finished

