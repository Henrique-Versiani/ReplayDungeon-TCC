extends Label

func _process(delta):
	$".".text = str("Coins: " + str(Settings.LoadCoinsValue()) )
