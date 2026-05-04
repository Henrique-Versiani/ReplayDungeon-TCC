extends RefCounted
class_name ChunkGenerator

func generate_chunk(
	chunk_id: int,
	base_seed: int,
	entry_x: int,
	chunk_start_z: int,
	chunk_width: int,
	chunk_depth: int,
	floor_y: int,
	floor_mesh: int,
	coin_mesh: int,
	coin_chance: float
) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(base_seed + chunk_id * 7919)

	var x_min: int = entry_x - int(chunk_width / 2.0)
	var x_max: int = x_min + chunk_width - 1
	var target_x: int = int(clamp(entry_x + rng.randi_range(-2, 2), x_min + 1, x_max - 1))
	var shape_type: int = rng.randi_range(0, 5)

	var floor_cells: Dictionary = {}
	var coin_cells: Dictionary = {}

	if chunk_id == 0:
		shape_type = 1
		target_x = entry_x
		
		for x in range(target_x - 3, target_x + 4):
			for step in range(6):
				_add_floor_cell(x, floor_y, chunk_start_z - step, floor_mesh, floor_cells)

	_add_entry_connector(entry_x, target_x, chunk_start_z, floor_y, floor_mesh, floor_cells)

	match shape_type:
		0:
			target_x = _build_line_shape(rng, target_x, chunk_start_z, chunk_depth, x_min, x_max, floor_y, floor_mesh, floor_cells)
		1:
			_build_square_shape(target_x, chunk_start_z, chunk_depth, chunk_width, floor_y, floor_mesh, floor_cells)
		2:
			_build_circle_shape(target_x, chunk_start_z, chunk_depth, chunk_width, floor_y, floor_mesh, floor_cells)
		3:
			target_x = _build_curve_shape(rng, target_x, chunk_start_z, chunk_depth, x_min, x_max, floor_y, floor_mesh, floor_cells)
		4:
			_build_holey_square_shape(rng, target_x, chunk_start_z, chunk_depth, chunk_width, floor_y, floor_mesh, floor_cells)
		5:
			_build_circle_path_shape(rng, target_x, chunk_start_z, chunk_depth, chunk_width, floor_y, floor_mesh, floor_cells)

	var trap_chance: float = 0.15
	var available_traps = [10, 6, 20] # SPIKE(10), SAW(6), SPINNER(7), BOX(20)

	for floor_key in floor_cells.keys():
		var floor_cell: Vector3i = floor_cells[floor_key]["cell"]
		var item_cell := Vector3i(floor_cell.x, floor_cell.y + 1, floor_cell.z)
		var item_key := _cell_key(item_cell)
		var rng_val = rng.randf()

		if rng_val <= coin_chance:
			coin_cells[item_key] = {"cell": item_cell, "mesh": coin_mesh, "orientation": 0}
			
		elif rng_val <= (coin_chance + trap_chance):
			var random_trap_mesh = available_traps[rng.randi() % available_traps.size()]
			coin_cells[item_key] = {"cell": item_cell, "mesh": random_trap_mesh, "orientation": 0}
		
		elif rng_val <= (coin_chance + 0.15):
			var trap_cell := Vector3i(floor_cell.x, floor_cell.y + 1, floor_cell.z) 
			var trap_key := _cell_key(trap_cell)
			coin_cells[trap_key] = {"cell": trap_cell, "mesh": 10, "orientation": 0}

	var cells: Array = []
	for cell_data in floor_cells.values():
		cells.append(cell_data)
	for coin_data in coin_cells.values():
		cells.append(coin_data)

	return {
		"cells": cells,
		"exit_x": target_x,
		"shape": shape_type
	}

func _build_line_shape(
	rng: RandomNumberGenerator,
	center_x: int,
	chunk_start_z: int,
	chunk_depth: int,
	x_min: int,
	x_max: int,
	floor_y: int,
	floor_mesh: int,
	floor_cells: Dictionary
) -> int:
	var current_x: int = center_x
	for step in range(chunk_depth):
		var z: int = chunk_start_z - step
		if step > 0 and step % 4 == 0:
			current_x = int(clamp(current_x + rng.randi_range(-1, 1), x_min + 1, x_max - 1))
		_add_floor_cell(current_x, floor_y, z, floor_mesh, floor_cells)
	return current_x

func _build_square_shape(
	center_x: int,
	chunk_start_z: int,
	chunk_depth: int,
	chunk_width: int,
	floor_y: int,
	floor_mesh: int,
	floor_cells: Dictionary
) -> void:
	var square_size: int = int(clamp(4, 3, max(3, chunk_width - 2)))
	var center_z: int = chunk_start_z - int(chunk_depth / 2.0)
	var half_size: int = int(square_size / 2.0)
	var x_start: int = center_x - half_size
	var x_end: int = center_x + half_size
	var z_start: int = center_z - half_size
	var z_end: int = center_z + half_size

	for step in range(chunk_depth):
		var z: int = chunk_start_z - step
		_add_floor_cell(center_x, floor_y, z, floor_mesh, floor_cells)

	for x in range(x_start, x_end + 1):
		for z in range(z_start, z_end + 1):
			_add_floor_cell(x, floor_y, z, floor_mesh, floor_cells)

func _build_circle_shape(
	center_x: int,
	chunk_start_z: int,
	chunk_depth: int,
	chunk_width: int,
	floor_y: int,
	floor_mesh: int,
	floor_cells: Dictionary
) -> void:
	var radius: int = int(max(2, int(chunk_width / 3.0)))
	var center_z: int = chunk_start_z - int(chunk_depth / 2.0)

	for step in range(chunk_depth):
		var z: int = chunk_start_z - step
		_add_floor_cell(center_x, floor_y, z, floor_mesh, floor_cells)

	for x in range(center_x - radius, center_x + radius + 1):
		for z in range(center_z - radius, center_z + radius + 1):
			var dx := x - center_x
			var dz := z - center_z
			if dx * dx + dz * dz <= radius * radius:
				_add_floor_cell(x, floor_y, z, floor_mesh, floor_cells)

func _build_curve_shape(
	rng: RandomNumberGenerator,
	center_x: int,
	chunk_start_z: int,
	chunk_depth: int,
	x_min: int,
	x_max: int,
	floor_y: int,
	floor_mesh: int,
	floor_cells: Dictionary
) -> int:
	var current_x: int = center_x
	var curve_direction: int = rng.randi_range(0, 1) # 0 = left curve, 1 = right curve
	
	for step in range(chunk_depth):
		var z: int = chunk_start_z - step
		# Curva em pares: muda de posição a cada 2 passos
		if step > 0 and step % 2 == 0:
			if curve_direction == 0:
				current_x = int(clamp(current_x - 1, x_min + 1, x_max - 1))
			else:
				current_x = int(clamp(current_x + 1, x_min + 1, x_max - 1))
		
		# Adiciona um bloco de largura em cada posição
		_add_floor_cell(current_x, floor_y, z, floor_mesh, floor_cells)
	
	return current_x

func _build_holey_square_shape(
	rng: RandomNumberGenerator,
	center_x: int,
	chunk_start_z: int,
	chunk_depth: int,
	chunk_width: int,
	floor_y: int,
	floor_mesh: int,
	floor_cells: Dictionary
) -> void:
	var square_size: int = int(clamp(4, 3, max(3, chunk_width - 2)))
	var center_z: int = chunk_start_z - int(chunk_depth / 2.0)
	var half_size: int = int(square_size / 2.0)
	var x_start: int = center_x - half_size
	var x_end: int = center_x + half_size
	var z_start: int = center_z - half_size
	var z_end: int = center_z + half_size
	var hole_chance: float = 0.15  # 15% de chance de buraco em cada célula interna

	# Conecta entrada ao quadrado
	for step in range(chunk_depth):
		var z: int = chunk_start_z - step
		_add_floor_cell(center_x, floor_y, z, floor_mesh, floor_cells)

	# Cria quadrado com buracos (pula algumas células internas)
	for x in range(x_start, x_end + 1):
		for z in range(z_start, z_end + 1):
			# Mantém as bordas sempre
			var is_border: bool = (x == x_start or x == x_end or z == z_start or z == z_end)
			if is_border or rng.randf() > hole_chance:
				_add_floor_cell(x, floor_y, z, floor_mesh, floor_cells)

func _build_circle_path_shape(
	_rng: RandomNumberGenerator,
	center_x: int,
	chunk_start_z: int,
	chunk_depth: int,
	chunk_width: int,
	floor_y: int,
	floor_mesh: int,
	floor_cells: Dictionary
) -> void:
	var radius: int = int(max(2, int(chunk_width / 3.0)))
	var center_z: int = chunk_start_z - int(chunk_depth / 2.0)
	var path_width: int = 1  # Largura do caminho circular

	# Conecta entrada ao círculo
	for step in range(chunk_depth):
		var z: int = chunk_start_z - step
		_add_floor_cell(center_x, floor_y, z, floor_mesh, floor_cells)

	# Cria o caminho circular (apenas o perímetro, não preenchido)
	for angle_step in range(0, 360, 15):  # Passos de 15 graus
		var angle_rad: float = deg_to_rad(angle_step)
		var x: int = int(center_x + radius * cos(angle_rad))
		var z: int = int(center_z + radius * sin(angle_rad))
		
		# Adiciona algumas células ao redor do ponto para fazer um caminho
		for offset_x in range(-path_width, path_width + 1):
			_add_floor_cell(x + offset_x, floor_y, z, floor_mesh, floor_cells)

func _add_entry_connector(
	entry_x: int,
	target_x: int,
	chunk_start_z: int,
	floor_y: int,
	floor_mesh: int,
	floor_cells: Dictionary
) -> void:
	var min_x: int = int(min(entry_x, target_x))
	var max_x: int = int(max(entry_x, target_x))
	for x in range(min_x, max_x + 1):
		_add_floor_cell(x, floor_y, chunk_start_z, floor_mesh, floor_cells)

func _add_floor_cell(x: int, y: int, z: int, mesh: int, floor_cells: Dictionary) -> void:
	var cell: Vector3i = Vector3i(x, y, z)
	var key: String = _cell_key(cell)
	floor_cells[key] = {"cell": cell, "mesh": mesh, "orientation": 0}

func _cell_key(cell: Vector3i) -> String:
	return str(cell.x) + "|" + str(cell.y) + "|" + str(cell.z)
