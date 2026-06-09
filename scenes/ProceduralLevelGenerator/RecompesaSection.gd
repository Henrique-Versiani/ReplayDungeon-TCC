extends BaseSection
class_name RecompensaSection

const SHAPE_COIN_TRAIL:		int = 0
const SHAPE_COIN_PATTERN:	int = 1
const SHAPE_TREASURE_ROOM:	int = 2

# ----- TIPOS DE PADROES GEOMETRICOS -----
const PATTERN_CIRCLE:	int = 0
const PATTERN_SQUARE:	int = 1
const PATTERN_DIAMOND:	int = 2
const PATTERN_STAR:		int = 3
const PATTERN_LINE:		int = 4

# ----- DENSIDADE DA TRILHA DE MOEDAS -----
const COIN_TRAIL_DENSITY:	float = 0.8

# ----- CHANCE DE BAU EM SHAPES QUE NAO FORCAM -----
const OPTIONAL_CHEST_CHANCE: float = 0.35

func _depth_min() -> int:	return 8
func _depth_max() -> int:	return 14
func _width_min() -> int:	return 5
func _width_max() -> int:	return 7
func type_name() -> String:	return "recompensa"

func build() -> Dictionary:
	var shape: int = rng.randi_range(0, 2)

	match shape:
		SHAPE_COIN_TRAIL:		_build_coin_trail()
		SHAPE_COIN_PATTERN:		_build_coin_pattern()
		SHAPE_TREASURE_ROOM:	_build_treasure_room()

	finalize()
	return get_result()

func _build_coin_trail() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)
	var trail_width: int = min(width, 3)
	var half_w: int = trail_width / 2

	for step in range(depth):
		var center_x: int = interpolated_x(step)
		var z: int = chunk_start_z - step
		for w_off in range(-half_w, half_w + 1):
			carve_floor(center_x + w_off, z)
		mark_main(center_x, z)

	for step in range(1, depth - 1):
		var center_x: int = interpolated_x(step)
		var z: int = chunk_start_z - step
		if rng.randf() < COIN_TRAIL_DENSITY:
			add_decoration(center_x, z, COIN)

	if rng.randf() < OPTIONAL_CHEST_CHANCE:
		var chest_step: int = depth / 2
		var chest_x: int = interpolated_x(chest_step)
		var chest_z: int = chunk_start_z - chest_step
		add_chest(chest_x, chest_z)

func _build_coin_pattern() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)
	var half_w: int = width / 2

	var corridor_in: int = 1
	var corridor_out: int = 1
	var area_depth: int = depth - corridor_in - corridor_out

	for step in range(corridor_in):
		carve_main(entry_x, chunk_start_z - step)

	var area_start_z: int = chunk_start_z - corridor_in
	var area_end_z: int = area_start_z - area_depth + 1
	carve_rect(entry_x - half_w, entry_x + half_w, area_end_z, area_start_z)

	for dz in range(area_depth):
		mark_main(entry_x, area_start_z - dz)

	if exit_x != entry_x:
		mark_main(exit_x, area_end_z)

	for step in range(corridor_in + area_depth, depth):
		carve_main(exit_x, chunk_start_z - step)

	var center_x: int = entry_x
	var center_z: int = area_start_z - area_depth / 2
	var max_radius: int = min(half_w, area_depth / 2)
	var radius: int = clamp(max_radius, 1, 3)
	_apply_pattern_coins(center_x, center_z, radius)

	if rng.randf() < OPTIONAL_CHEST_CHANCE:
		add_chest(center_x, center_z)

func _build_treasure_room() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)

	var corridor_in_len: int = 2
	var max_room_side: int = max(3, depth - corridor_in_len - 2)
	var room_side: int = min(rng.randi_range(4, 5), max_room_side)
	var corridor_out_start: int = corridor_in_len + room_side
	var half: int = (room_side - 1) / 2

	for step in range(corridor_in_len):
		carve_main(entry_x, chunk_start_z - step)

	var room_first_z: int = chunk_start_z - corridor_in_len
	var room_last_z: int = room_first_z - (room_side - 1)
	carve_rect(entry_x - half, entry_x + half, room_last_z, room_first_z)

	for z_idx in range(room_side):
		mark_main(entry_x, room_first_z - z_idx)

	var chest_z: int = room_first_z - room_side / 2
	add_chest(entry_x, chest_z)

	_apply_pattern_coins(entry_x, chest_z, half)

	if exit_x != entry_x:
		mark_main(exit_x, room_last_z)

	for step in range(corridor_out_start, depth):
		carve_main(exit_x, chunk_start_z - step)

func _apply_pattern_coins(center_x: int, center_z: int, radius: int) -> void:
	"""
	APLICA UM PADRAO GEOMETRICO ALEATORIO DE MOEDAS CENTRADO EM
	(center_x, center_z) COM O RAIO INDICADO.

	SE A CELULA JA ESTA OCUPADA (EX: BAU NO CENTRO), A MOEDA E IGNORADA.
	SE NAO HA CHAO NA CELULA, IGNORADA TAMBEM.
	"""
	var pattern_type: int = rng.randi_range(0, 4)
	var cells: Array

	match pattern_type:
		PATTERN_CIRCLE:		cells = _pattern_circle(center_x, center_z, radius)
		PATTERN_SQUARE:		cells = _pattern_square_outline(center_x, center_z, radius)
		PATTERN_DIAMOND:	cells = _pattern_diamond(center_x, center_z, radius)
		PATTERN_STAR:		cells = _pattern_star(center_x, center_z, radius)
		PATTERN_LINE:		cells = _pattern_line(center_x, center_z, radius)

	for cell in cells:
		add_decoration(cell.x, cell.z, COIN)

func _pattern_circle(cx: int, cz: int, r: int) -> Array:
	"""
	CONTORNO DE CIRCULO. CELULAS ONDE d^2 ESTA PROXIMO DE r^2.
	"""
	var cells: Array = []
	var r2: int = r * r
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var d2: int = dx * dx + dz * dz
			# BANDA ESTREITA EM TORNO DE r^2
			if abs(d2 - r2) <= 1:
				cells.append(Vector3i(cx + dx, floor_y, cz + dz))
	return cells

func _pattern_square_outline(cx: int, cz: int, half_side: int) -> Array:
	"""
	CONTORNO DE QUADRADO. CELULAS NA BORDA DE UM QUADRADO DE LADO 2*half_side+1.
	"""
	var cells: Array = []
	for dx in range(-half_side, half_side + 1):
		for dz in range(-half_side, half_side + 1):
			if abs(dx) == half_side or abs(dz) == half_side:
				cells.append(Vector3i(cx + dx, floor_y, cz + dz))
	return cells

func _pattern_diamond(cx: int, cz: int, r: int) -> Array:
	"""
	CONTORNO DE LOSANGO. CELULAS COM |dx| + |dz| == r.
	"""
	var cells: Array = []
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			if abs(dx) + abs(dz) == r:
				cells.append(Vector3i(cx + dx, floor_y, cz + dz))
	return cells

func _pattern_star(cx: int, cz: int, r: int) -> Array:
	"""
	ESTRELA DE 8 PONTAS (CRUZ + X). BRACOS CARDINAIS E DIAGONAIS DE COMPRIMENTO r.
	"""
	var cells: Array = []
	for d in range(1, r + 1):
		# BRACOS CARDINAIS
		cells.append(Vector3i(cx + d, floor_y, cz))
		cells.append(Vector3i(cx - d, floor_y, cz))
		cells.append(Vector3i(cx, floor_y, cz + d))
		cells.append(Vector3i(cx, floor_y, cz - d))
		# BRACOS DIAGONAIS
		cells.append(Vector3i(cx + d, floor_y, cz + d))
		cells.append(Vector3i(cx - d, floor_y, cz - d))
		cells.append(Vector3i(cx + d, floor_y, cz - d))
		cells.append(Vector3i(cx - d, floor_y, cz + d))
	return cells

func _pattern_line(cx: int, cz: int, length: int) -> Array:
	"""
	LINHA RETA HORIZONTAL OU VERTICAL DE COMPRIMENTO 2*length+1 (CENTRADA).
	"""
	var cells: Array = []
	var horizontal: bool = rng.randi_range(0, 1) == 0
	if horizontal:
		for dx in range(-length, length + 1):
			cells.append(Vector3i(cx + dx, floor_y, cz))
	else:
		for dz in range(-length, length + 1):
			cells.append(Vector3i(cx, floor_y, cz + dz))
	return cells