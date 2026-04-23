extends CanvasLayer

@onready var first_input = $MarginContainer/Control/Patterns/FirstInput
@onready var second_input = $MarginContainer/Control/Patterns/SecondInput

var inputs_images = [
	preload("res://assets/web-trap-input-ui/arrow_e.png"),
	preload("res://assets/web-trap-input-ui/arrow_w.png"),
	preload("res://assets/web-trap-input-ui/arrow_n.png"),
	preload("res://assets/web-trap-input-ui/arrow_s.png"),
]
var inputs_direction = []
var inputs = []
var count: int = 0
var is_shaking: bool = false
var shake_duration: float = 0.05
var shake_intensity: float = 2.5
signal free_player


"""
TODO ESSE CODIGO PRECISA DE REVISAO, ISSO AQUI EH SO UMA VERSAO PREMATURA DO QUE O INPUT WEB PODE SER.
EXISTE MUITO ESPACO PARA MELHORAR. Se alguem quiser pensar numa logica melhor e mudar as coisas, sinta-se a vontade.
"""

func _ready():
	var direction_dict:Dictionary = {
		0 : "right",
		1 : "left",
		2 : "up",
		3 : "down"
	}
	randomize()
	for i in range(0,4):
		var num:int = randi_range(0,3)
		inputs.append({"Direction": direction_dict[num], "image": inputs_images[num]})

func ShowInputPuzzle():
	if inputs.size() > 0:
		first_input.texture = inputs[0]["image"]
	else:
		first_input.texture = null

func _unhandled_input(_event):	
	
	if (_event is InputEventKey or _event is InputEventAction) and _event.pressed == false:
		if inputs.size() > 0:
			inputs_direction = CheckInputSequence(_event)
			if inputs_direction == inputs[0]["Direction"]:
				if Settings.enable_sound: $HitSFX.play()
				AnimateInputTransition(first_input)
				if inputs.size() == 1:
					DeleteSelf()
			elif !is_shaking:
				if Settings.enable_sound: $MissSFX.play()
				ShakeInputUI()
		else:
			DeleteSelf()	
			#InputEventAction: action="up", pressed=false
func CheckInputSequence(event):
	var input_direction:String
	var direction:int
	if event is InputEventAction:
		direction = 0
		input_direction = event.action
		return input_direction
		
	else:
		direction = event.keycode
	
		if direction == 68:
			input_direction = "right"
		elif direction == 65:
			input_direction = "left"
		elif direction ==  87:
			input_direction = "up"
		elif direction == 83:
			input_direction = "down" 
		else:
			input_direction = "nodirection"

		return input_direction

func DeleteSelf():
	self.queue_free()
	free_player.emit()
	
func ShakeInputUI():
	"""
	VERSAO IMPROVISADA DE UMA ANIMADAO DE SHAKE, FUNCIONA mas eu acho que existe um jeito mais inteligente de ser feito
	"""
	
	var input_node = first_input
	
	if input_node:
		is_shaking = true
		var _x = input_node.position.x
		var _color = input_node.modulate
		var tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(input_node, "modulate", Color.RED, shake_duration)
		tween.tween_property(input_node, "position:x", _x + shake_intensity, shake_duration)
		tween.tween_property(input_node, "position:x", _x, shake_duration)
		tween.tween_property(input_node, "position:x", _x - shake_intensity, shake_duration)
		tween.tween_property(input_node, "position:x", _x, shake_duration)
		tween.tween_property(input_node, "modulate", _color, shake_duration)
		await tween.finished
		is_shaking = false

func SkipInput(value: int):
	for i in range(value):
		inputs.pop_front()

func AnimateInputTransition(node: TextureRect):
	var tween = create_tween()
	tween.tween_property(node, "scale", Vector2(0.0, 0.0), 0.025)
	await tween.finished
	inputs.pop_front()
	if inputs.size() > 0:
		ShowInputPuzzle()
		var tween2 = create_tween()
		tween2.tween_property(node, "scale", Vector2(1.0, 1.0), 0.025)
		await tween2.finished
		
