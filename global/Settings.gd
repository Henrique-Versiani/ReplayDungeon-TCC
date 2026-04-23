extends Node

var highscore_file 	= "user://highscore.save"
var settings_file 	= "user://settings.save"
var coins_file 		= "user://coins.save"
var enable_sound: bool = true
var enable_music: bool = true

func _ready():
	LoadSettings()

func SaveSettings():
	var file = FileAccess.open(Settings.settings_file, FileAccess.WRITE)
	file.store_var(enable_music)
	file.store_var(enable_sound)
	file.close()

func LoadSettings():
	var file = FileAccess.open(Settings.settings_file, FileAccess.READ)
	if file:
		enable_music = file.get_var(enable_music)
		enable_sound = file.get_var(enable_sound)
		file.close()

func LoadHighScore():
	var file = FileAccess.open(Settings.highscore_file, FileAccess.READ)
	if file:
		var highscore: int = file.get_var()
		file.close()
		return highscore
	return 0

func LoadCoinsValue():
	var file = FileAccess.open(Settings.coins_file, FileAccess.READ)
	if file:
		var coins: int = file.get_var()
		file.close()
		return coins
	return 0
	
func SaveHighScore(_value):
	var file = FileAccess.open(Settings.highscore_file, FileAccess.WRITE)
	if file:
		file.store_var(_value)
		file.close()

func SaveCoins(_value):
	var value = _value + LoadCoinsValue()
	var file = FileAccess.open(Settings.coins_file, FileAccess.WRITE)
	if file:
		file.store_var(value)
		file.close()
