extends TRAP

var animation_timer: float = 0
var switch_interval: float = 1.0
var trap_state: TrapState = TrapState.hidden

func _ready():
	$AnimationPlayer.play("idle")
	$arrow.hide()
	
func _process(delta):
	if trap_state == TrapState.disabled:
		return
	animation_timer += delta
	if animation_timer >= switch_interval:
		SwitchAnimation()
		animation_timer = 0

func SwitchAnimation():
	if trap_state == TrapState.hidden:
		$arrow/CollisionShape3D.disabled = false
		$arrow.show()
		$AnimationPlayer.play("Spear Trap_Shoot")
		if Settings.enable_sound:$ShooterSFX.play()
		trap_state = TrapState.active

func _on_arrow_body_entered(body):
	if trap_state == TrapState.active:
		#TRAP.MovePlayer(body)
		TRAP.KillPlayer(body)
		

func _on_arrow_area_entered(area):
	if is_instance_of(area.get_parent_node_3d(), GOLEM):
		if area.get_parent().GetHitCount() > 0:
			if $AnimationPlayer.is_playing():
				#CRIAR ANIMACAO DE QUEBRA DO ARROW
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
	trap_state = TRAP.ForceDisabledMode()
	$AnimationPlayer.play("idle")

func Enable():
	trap_state = TRAP.ForceEnabledMode()
	trap_state = TrapState.hidden


