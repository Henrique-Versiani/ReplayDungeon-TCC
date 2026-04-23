extends Control

var tween: Tween

@onready var colors: Control = $ButtonControl/Button/Colors

var colors_list: Array
var inverted_color_list: Array

func _ready():
	for child in colors.get_children():
		colors_list.append(child)

	colors_list.reverse()
	for child in colors_list:
		inverted_color_list.append(child)
	colors_list.reverse()
	
func HoverOn() -> void:
	var idx: int = 0
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	
	for child in colors_list:
		tween.parallel().tween_property(child, "position:y", 0.0, 0.3 + idx * randf_range(0.08, 0.15))
		idx += 1
	

func HoverOff() -> void:
	var idx: int = 0
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	for child in inverted_color_list:
		tween.parallel().tween_property(child, "position:y", 68, 0.3 + idx * randf_range(0.15, 0.2))
		idx += 1

func _on_button_mouse_entered():
	HoverOn()


func _on_button_mouse_exited():
	HoverOff()
