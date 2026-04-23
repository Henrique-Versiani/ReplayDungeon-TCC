extends Node

signal game_started

var music_buttons = {true: preload("res://assets/buttons/flat-dark/flatDark16.png"), false: preload("res://assets/buttons/flat-dark/flatDark18.png")}
var sound_buttons = {true: preload("res://assets/buttons/flat-dark/flatDark12.png"), false: preload("res://assets/buttons/flat-dark/flatDark14.png")}
var current_screen = null
var timer
var time: float = 0.5

func _ready():
	register_buttons()
	change_screen($TittleScreen)

func register_buttons():
	var buttons = get_tree().get_nodes_in_group("buttons")
	for button in buttons:
		button.connect("pressed", _on_button_pressed.bind(button))
		match button.name:
			"Sound":
				button.texture_normal = sound_buttons[Settings.enable_sound]
			"Music":
				button.texture_normal = music_buttons[Settings.enable_music]
				
func _on_button_pressed(button):
	if Settings.enable_sound: $Click.play()
	match button.name:
		"Home":
			$"../GameMusic".stop()
			if Settings.enable_music: $"../MenuMusic".play()
			change_screen($TittleScreen)
		"Play":
			$"../Player".InitPlayer()
			$"../GridMap".Init()
			change_screen(null)
			$"../HUD".show()
			$"../CameraFrontal".SwitchToPrincipal()
			$"../Player".PlayerLightOn()
			$"../MenuMusic".stop()
			if Settings.enable_music: $"../GameMusic".play()
			game_started.emit() #PLAYER.GD
		"Settings":
			change_screen($SettingsScreen)
		"Shop":
			$"../Player".InitPlayer()
			$"../CameraFrontal".SwitchToStore()
			$"../Player".PlayerLightOn()
			change_screen($CharacterScreen)
		"Return":
			$"../Player".PlayerLightOff()
			$"../CameraFrontal".SwitchToOriginalPos()
			$"../GameMusic".stop()
			if Settings.enable_music: $"../MenuMusic".play()
			change_screen($TittleScreen)
		"Sound":
			Settings.enable_sound = !Settings.enable_sound
			button.texture_normal = sound_buttons[Settings.enable_sound]
			Settings.SaveSettings()
		"Music":
			Settings.enable_music = !Settings.enable_music
			button.texture_normal = music_buttons[Settings.enable_music]
			Settings.SaveSettings()
			if Settings.enable_music: $"../MenuMusic".play()
			else: $"../MenuMusic".stop()
		"Left":
			Store.NavigateLeft()
		"Right":
			Store.NavigateRight()
			
func change_screen(new_screen):
	if current_screen:
		current_screen.disappear()
	current_screen = new_screen
	if new_screen:
		current_screen.appear()
