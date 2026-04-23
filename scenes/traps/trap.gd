extends Node3D
class_name TRAP

enum TrapState {active, disabled, hidden}
@export var switch_interval: float = 1.0 

var animation_timer: float = 0.0
var trap_state: TrapState = TrapState.active

func _process(delta):
	if trap_state == TrapState.disabled:
		return
		
	animation_timer += delta
	if animation_timer >= switch_interval:
		_switch_animation()
		animation_timer = 0.0

func _switch_animation():
	pass

func Disable():
	trap_state = TrapState.disabled

func Enable(starting_state: TrapState = TrapState.hidden):
	trap_state = starting_state

static func KillPlayer(body):
	if body.has_method("Die"):
		body.Die()

static func MovePlayer(body):
	if body.has_method("Move") and !body.player_died:
		await body.Move(Vector2.RIGHT * 5, true)
		body.Die()
