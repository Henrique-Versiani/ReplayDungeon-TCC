extends CharacterBody3D

class_name ENEMY

static func KillPlayer(body):
	if body.has_method("Die"):
		body.Die()
