extends Node3D

class_name TRAP
enum TrapState {active, disabled, hidden}

static func KillPlayer(body):
	"""FUNCAO AUTO-EXPLICATIVA..."""
	if body.has_method("Die"):
		body.Die()

static func MovePlayer(body):
	if body.has_method("Move") and !body.player_died:
		await body.Move(Vector2.RIGHT * 5, true)
		body.Die()

static func ForceDisabledMode():
	print("desabilitou")
	return TrapState.disabled
		
static func ForceEnabledMode():
	print("reabilitou")
	return TrapState.active

static func ForceHiddenMode():
	print("hidden")
	return TrapState.hidden
		
