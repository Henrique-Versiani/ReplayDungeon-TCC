
extends TRAP

var switch_interval: float = 1.0 #randf_range(1.0, 3.25)
var animation_timer: float
var temp_body
var trap_state: TrapState = TrapState.active

func _ready():
	$AnimationPlayer.play("idle")
	
func _process(delta):
	if trap_state == TrapState.disabled: return
	animation_timer += delta
	if animation_timer >= switch_interval:
		SwitchAnimation()
		animation_timer = 0
		
func SwitchAnimation():
	if trap_state == TrapState.hidden:
		$AnimationPlayer.play("shot")
		$SlimeSFX.play()
		trap_state = TrapState.active
	else:
		$AnimationPlayer.play("idle")
		trap_state = TrapState.hidden

func Disable():
	trap_state = TRAP.ForceDisabledMode()
	$AnimationPlayer.play("idle")

func Enable():
	trap_state = TRAP.ForceEnabledMode()
	trap_state = TrapState.hidden


func _on_fire_ball_body_entered(body):
	TRAP.KillPlayer(body)
	pass # Replace with function body.
