extends TRAP

var move_speed: 	float = randf_range(1.0, 2.5)
var rotation_speed: float = 5.0
var x_range:		float = 2
var direction:		int = 1
var initial_offset:	float = 0.0

func _ready():
	initial_offset = $Center.position.x

func _process(delta):
	"""
	GIRA A SERRA E INTERPOLA A POSICAO DELA ATE O RANGE E DEPOIS INVERTE A DIRECAO.
	O MOVIMENTO E SEMPRE NO X LOCAL. PARA SERRAS VERTICAIS, O SPAWNER ROTACIONA
	O NO INTEIRO 90 EM Y, ENTAO O X LOCAL VIRA O Z DO MUNDO E O VISUAL ACOMPANHA.
	"""
	if trap_state == TrapState.active:
		$Center.rotation.z += rotation_speed * delta
		$Center.position.x += move_speed * delta * direction
	if abs($Center.position.x) > abs(initial_offset + x_range):
		direction *= -1
	$CollisionShape3D.position = $Center.position

func _on_body_entered(body):
	if trap_state == TrapState.active:
		TRAP.KillPlayer(body)

func Disable():
	super.Disable()
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($".", "position:y", position.y - 0.25, 0.5)
	await tween.finished

func Enable(starting_state: TrapState = TrapState.active):
	super.Enable(starting_state)
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($".", "position:y", position.y + 0.25, 0.5)
	await tween.finished
