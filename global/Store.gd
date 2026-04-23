extends Node


var CHARACTERS: Dictionary = {
	"Robot": preload("res://scenes/player/characters/Robot/Robot.tres"),
	"Blaze": preload("res://scenes/player/characters/Blaze/Blaze.tres")
}

var CURRENT_CHARACTER: String
var INDEX: int = 0

func LoadToCurrentCharacter():
	CURRENT_CHARACTER = CHARACTERS.keys()[INDEX]
	var character_resource = CHARACTERS[CURRENT_CHARACTER]
	var main = get_parent().get_child(2)
	main.get_child(2).character = character_resource
	main.get_child(2).UpdateCharacter()
	
func NavigateLeft():
	INDEX -= 1
	if INDEX < 0:
		INDEX = CHARACTERS.size() - 1
	LoadToCurrentCharacter()

func NavigateRight():
	INDEX += 1
	if INDEX >= CHARACTERS.size():
		INDEX = 0
	LoadToCurrentCharacter()
