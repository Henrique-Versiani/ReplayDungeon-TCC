extends ENEMY

func _on_esquentadinho_model_body_entered(body):
	ENEMY.KillPlayer(body)
