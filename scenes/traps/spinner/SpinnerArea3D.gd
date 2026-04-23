extends TRAP

func Disable():
	$"..".trap_state = TRAP.ForceDisabledMode()

func Enable():
	$"..".trap_state = TRAP.ForceEnabledMode()
