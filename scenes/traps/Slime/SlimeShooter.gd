extends TRAP

@onready var splash_scene  = preload("res://scenes/traps/Slime/slime_screen.tscn")
var switch_interval: float = 1.0 #randf_range(2.5, 4.0)
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
		if Settings.enable_sound:$SlimeSFX.play()
		trap_state = TrapState.active
	else:
		$AnimationPlayer.play("idle")
		trap_state = TrapState.hidden

func _on_slime_body_entered(body):
	temp_body = body
	if $AnimationPlayer.is_playing():
		$AnimationPlayer.stop()
		var slime_on_screen = splash_scene.instantiate()
		add_child(slime_on_screen)
		slime_on_screen.AssingSplashPositions()

func Disable():
	trap_state = TRAP.ForceDisabledMode()
	$AnimationPlayer.play("idle")

func Enable():
	trap_state = TRAP.ForceEnabledMode()
	trap_state = TrapState.hidden
