extends TRAP

var temp_body

var switch_interval: float = 4.5
var animation_timer: float = 0.0

var trap_state: TrapState = TrapState.active

var is_pushing: bool = false

func _ready():
	$AnimationPlayer.play("push")
	
func _on_area_3d_body_entered(body):
	if !body.has_method("Move"): return
	if is_pushing:
		if round(rad_to_deg($".".rotation.y)) == 0:
			body.Move(Vector2.RIGHT * 3, true)
			if Settings.enable_sound:$PusherHitSFX.play()
		if round(rad_to_deg($".".rotation.y)) == -180:
			body.Move(Vector2.LEFT * 3, true)
			if Settings.enable_sound:$PusherHitSFX.play()
		if round(rad_to_deg($".".rotation.y)) == -90:
			body.Move(Vector2.DOWN * 3, true)
			if Settings.enable_sound:$PusherHitSFX.play()
		if round(rad_to_deg($".".rotation.y)) == 90:
			body.Move(Vector2.UP * 3, true)
			if Settings.enable_sound:$PusherHitSFX.play()
			

func _process(delta):
	if trap_state == TrapState.disabled:
		return
	animation_timer += delta
	if animation_timer >= switch_interval:
		SwitchAnimation()
		animation_timer = 0

func SwitchAnimation():
	if trap_state == TrapState.active:
		$AnimationPlayer.play("retract")
		trap_state = TrapState.hidden
		
	elif trap_state == TrapState.hidden:
		$AnimationPlayer.play("push")
		trap_state = TrapState.active
		
func _on_animation_player_animation_finished(anim_name):
	if anim_name == "push":
		is_pushing = false

func _on_animation_player_animation_started(anim_name):
	if anim_name == "push":
		is_pushing = true
		


