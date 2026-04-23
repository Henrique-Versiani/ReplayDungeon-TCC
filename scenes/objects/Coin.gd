extends Area3D
var time: float = 0.0
var grabbed: bool = false

func _process(delta):
	rotate_y(2 * delta)
	position.y += (cos(time * 5) * 0.5) * delta 
	time += delta

func _on_body_entered(body):
	if body.has_method("CollectCoin") and !grabbed:
		body.CollectCoin(1)
		$".".queue_free() 
		grabbed = true

