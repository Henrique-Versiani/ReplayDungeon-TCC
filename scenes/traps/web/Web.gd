extends Area3D

@onready var input_scene = preload("res://scenes/screens/HUD/WebPuzzle.tscn")

var temp_body
var active: bool = true

func _on_body_entered(body):
	if active:
		temp_body = body
		body.can_move = false
		var inputs_instance = input_scene.instantiate()
		add_child(inputs_instance)
		inputs_instance.connect("free_player", FreePlayer)
		if body.player_character.has_method("PassCobWeb"):
			print("entrou")
			var blaze_pass_inputs_puzzle_value = body.player_character.PassCobWeb(body.player_character.getPassiveLevel())
			inputs_instance.SkipInput(blaze_pass_inputs_puzzle_value)
		inputs_instance.ShowInputPuzzle()

func FreePlayer():
	$AnimationPlayer.play("disappear")
	$CollisionShape3D.queue_free()
	temp_body.can_move = true
	active = !active

"""
BUG: Se estiver na teia o spinner bate no player, ele nao se mexe por que o player esta no estado can_move = false
bug ou feature?
"""
