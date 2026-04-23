extends TRAP

@onready var splash_scene  = preload("res://scenes/traps/Slime/slime_screen.tscn")
var temp_body

func _ready():
	trap_state = TrapState.active
	$AnimationPlayer.play("idle")

func _switch_animation():
	if trap_state == TrapState.hidden:
		$AnimationPlayer.play("shot")
		if Settings.enable_sound: $SlimeSFX.play()
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
	$AnimationPlayer.play("idle")
	super.Disable()
