extends TRAP

func _ready():
	trap_state = TrapState.active
	$AnimationPlayer.play("idle")

func _switch_animation():
	if trap_state == TrapState.hidden:
		$AnimationPlayer.play("shot")
		$SlimeSFX.play()
		trap_state = TrapState.active
	else:
		$AnimationPlayer.play("idle")
		trap_state = TrapState.hidden

func _on_fire_ball_body_entered(body):
	if trap_state == TrapState.active:
		TRAP.KillPlayer(body)

func Disable():
	$AnimationPlayer.play("idle")
	super.Disable()
