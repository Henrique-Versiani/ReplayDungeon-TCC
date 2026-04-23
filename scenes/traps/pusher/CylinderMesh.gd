@tool
extends MeshInstance3D

@onready var cut_off = $CutOff
	
func _process(delta):
	material_override.set_shader_parameter("cutplane", cut_off.global_transform)
