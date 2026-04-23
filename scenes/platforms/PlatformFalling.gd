extends Node3D

var time: float = 0.0
var amplitude: float = 0.5 
var frequency: float = 20.0
var active: bool = false 
	
signal erase_platform_falling

func _process(delta):
	if active:
		position.x += (cos(time * frequency) * amplitude) * delta
		position.y += (cos(time * 10) * 0.5) * delta 
		position.z += (cos(time * frequency) * amplitude) * delta 
		rotation.x += (cos(time * frequency) * amplitude) * delta
		rotation.z += (cos(time * frequency) * amplitude) * delta 
		time += delta

func _on_body_entered(body):
	if active == false:
		$Timer.timeout.connect(PlatformTimerTimeout.bind(body.position))
		active = true
		if Settings.enable_sound: $FallingSFX.play()
		$Timer.start()
		
func PlatformTimerTimeout(_position) -> void:
	"""
	FUNCAO CONECTADA COM O SINAL DE TIMEOUT DO TIMER
	"""
	erase_platform_falling.emit()
	$Timer.stop()
	
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "position:y", _position.y - 20, 1)
	
	await tween.finished
	self.queue_free()

