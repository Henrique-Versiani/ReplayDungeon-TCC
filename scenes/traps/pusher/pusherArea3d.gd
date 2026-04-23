extends TRAP

func Disable():
	print("entrou", self)
	"""ISSO AQUI PODE MELHORAR A ANIMACAO DE VOLTAR QUANDO DESABILITA NAO TA FLUIDA"""
	if $"../AnimationPlayer".is_playing():
		$"../AnimationPlayer".pause()
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.tween_property($"../TipMesh", "position", Vector3.ZERO, 0.125)
	tween.tween_property($"../CylinderMesh", "scale:y", 0, 0.01)
	tween.tween_property($"../CollisionShape3D", "position", Vector3.ZERO, 0.125)
	await tween.finished
	$"..".trap_state = TRAP.ForceDisabledMode()

func Enable():
	$"..".trap_state = TRAP.ForceHiddenMode()
