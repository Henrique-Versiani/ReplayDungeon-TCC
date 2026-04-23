extends TRAP

func _ready():
	trap_state = TrapState.hidden
	$AnimationPlayer.play("idle")
	$arrow.hide()

func _switch_animation():
	if trap_state == TrapState.hidden:
		$arrow/CollisionShape3D.disabled = false
		$arrow.show()
		$AnimationPlayer.play("Spear Trap_Shoot")
		if Settings.enable_sound: $ShooterSFX.play()
		trap_state = TrapState.active

func _on_arrow_body_entered(body):
	if trap_state == TrapState.active:
		TRAP.KillPlayer(body)
		
func _on_arrow_area_entered(area):
	if is_instance_of(area.get_parent_node_3d(), GOLEM):
		if area.get_parent().GetHitCount() > 0:
			if $AnimationPlayer.is_playing():
				_on_animation_player_animation_finished("Spear Trap_Shoot")
				area.get_parent().hit_count -= 1
		else:
			area.get_parent().DestroyGolem()

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "Spear Trap_Shoot":
		trap_state = TrapState.hidden
		$arrow/CollisionShape3D.disabled = true
		$arrow.hide()
		$AnimationPlayer.play("idle")

func Disable():
	while $AnimationPlayer.is_playing():
		await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("idle")
	super.Disable()
