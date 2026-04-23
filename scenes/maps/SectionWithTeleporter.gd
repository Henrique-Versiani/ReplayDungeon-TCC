extends GridMap

func GetTeleporterPosition(global_max_z):
	var grid = get_used_cells()
	var tp_position = []
	for pos in grid:
		if get_cell_item(pos) == 11:
			pos.z += -global_max_z + 1
			tp_position.append(pos)

	return tp_position
