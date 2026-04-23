extends TRAP

func Disable():
	$"..".Disable()

func Enable(starting_state: TrapState = TrapState.hidden):
	$"..".Enable(starting_state)
