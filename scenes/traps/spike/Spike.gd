extends TRAP

func _ready():
	trap_state = TrapState.active
	switch_interval = 3.0 
	$trap/AnimationPlayer.play("show")

func _process(delta):
	if trap_state == TrapState.active and $RayCast3D.is_colliding():
		TRAP.KillPlayer($RayCast3D.get_collider())
		Disable()
	super._process(delta)

func _switch_animation():
	if trap_state == TrapState.hidden:
		$trap/AnimationPlayer.play("show")
		if Settings.enable_sound: $SpikeActiveSFX.play()
		trap_state = TrapState.active
	else:
		$trap/AnimationPlayer.play("hide")
		trap_state = TrapState.hidden

func _on_body_entered(body):
	if trap_state == TrapState.active:
		Disable()
		TRAP.KillPlayer(body)

func Disable():
	$trap/AnimationPlayer.play("hide")
	super.Disable()
