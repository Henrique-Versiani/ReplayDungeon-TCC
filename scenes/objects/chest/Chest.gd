extends StaticBody3D
class_name CHEST
var opened: bool = false
var player_group: String = "player"
var front_group: String = "front_of_chest"
var temp_body 

func _process(delta):
	if $RayCast3D.is_colliding() and $RayCast3D.get_collider() != null and $RayCast3D.get_collider().is_in_group(player_group):
		$RayCast3D.get_collider().add_to_group(front_group)
		var is_player_in_front: bool = $RayCast3D.get_collider().is_in_group(front_group)
		if !opened and is_player_in_front:
			temp_body = $RayCast3D.get_collider()
	if temp_body and !$RayCast3D.is_colliding():
		temp_body.remove_from_group(front_group)
		
func OpenChest():
	#ARRUMAR CASO O PLAYER SEJA O ROBOT E PEGUE O DOBRO DE MOEDAS NO BAU VAI PRECISAR ATUALIZAR O TEXTO DA LABEL3D PARA +10
	#E MUDAR ROTACAO DO TEXTO OLHANDO SEMPRE PARA FRENTE
	if temp_body and !opened:
		$ChestSFX.stop()
		if Settings.enable_sound: $ChestOpenSFX.play()
		opened = true
		temp_body.CollectCoin(5)
		$AnimationPlayer.play("open")
		var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
		tween.parallel().tween_property($Label3D, "position:y", 3, 0.5)
		tween.parallel().tween_property($Label3D, "scale", Vector3(3.5,3.5,3.5), 0.25)
		await tween.finished
		$Timer.start()

func _on_timer_timeout():
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property($Label3D, "position:y", 0, 0.5)
	tween.parallel().tween_property($Label3D, "scale", Vector3(0,0,0), 0.25)
	await tween.finished	
