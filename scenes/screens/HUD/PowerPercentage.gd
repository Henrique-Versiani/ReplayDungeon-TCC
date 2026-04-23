extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if self.material.get_shader_parameter("value") >= 1:
		self.material.set_shader_parameter("value",1)
	pass
