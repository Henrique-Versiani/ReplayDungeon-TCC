extends AudioStreamPlayer3D


# Called when the node enters the scene tree for the first time.
func _ready():
	if Settings.enable_sound: play()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_finished():
	if Settings.enable_sound: play()
	pass # Replace with function body.
