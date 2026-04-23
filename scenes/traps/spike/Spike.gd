extends TRAP

var trap_state: TrapState = TrapState.active
var animation_timer:float = 0
var switch_interval:int = 3

func _ready():
	$trap/AnimationPlayer.play("show")

func _process(delta):
	"""
	RAYCAST VERTICAL QUE VERIFICA SE O PLAYER ESTA EM CIMA DA TRAP QUANDO ELA MUDA PARA O ESTADO ATIVO
	CONTA O TEMPO USANDO O DELTA E ATIVA A ANIMACAO
	"""
	if trap_state == TrapState.disabled:
		return
	if $RayCast3D.is_colliding() and trap_state == TrapState.active:
		TRAP.KillPlayer($RayCast3D.get_collider())
		trap_state = TRAP.ForceDisabledMode()
	animation_timer += delta
	if animation_timer >= switch_interval:
		SwitchAnimation()
		animation_timer = 0

func SwitchAnimation():
	if trap_state == TrapState.hidden:
		$trap/AnimationPlayer.play("show")
		if Settings.enable_sound:$SpikeActiveSFX.play()
		trap_state = TrapState.active
	else:
		$trap/AnimationPlayer.play("hide")
		trap_state = TrapState.hidden

func _on_body_entered(body):
	if trap_state == TrapState.active:
		trap_state = TRAP.ForceDisabledMode()
		TRAP.KillPlayer(body)

func Disable():
	trap_state = TRAP.ForceDisabledMode()
	$trap/AnimationPlayer.play("hide")

func Enable():
	trap_state = TRAP.ForceEnabledMode()
	trap_state = TrapState.hidden

