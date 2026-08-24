extends BaseSection
class_name RiscoSection

const SHAPE_SKELETON_ARENA:	int = 0
const SHAPE_CROSSFIRE:		int = 1

# ----- ARENA: ANEL -----
const ARENA_RING_RADIUS:	int = 3		# DISTANCIA DO ANEL AO CENTRO
const ARENA_ROOM_MARGIN:	int = 1		# MARGEM ENTRE O ANEL E A PAREDE DA SALA
const RING_SQUARE:			int = 0		# CONTORNO QUADRADO (DIST. CHEBYSHEV)
const RING_DIAMOND:			int = 1		# CONTORNO LOSANGO (DIST. MANHATTAN)
const RING_CIRCLE:			int = 2		# CONTORNO CIRCULAR

# ----- ARENA: INIMIGOS -----
const GUARD_SKELETON:		int = 0		# 1 ESQUELETO (PERSEGUE)
const GUARD_FIRE_CIRCLE:	int = 1		# 1 FIRE CIRCLE (GIRA COM RAIO 2)
const GUARD_FIRE_HORIZ:		int = 2		# 3 FIRE HORIZONTALS (ANDAM 3 P/ CADA LADO)
const ARENA_GUARD_OFFSET:	int = 1		# GUARDIAO CENTRAL FICA 1 CELULA AO LADO DO CENTRO
const NUM_FIRE_HORIZ:		int = 3

# ----- BURACOS -----
const HOLE_CHANCE_ARENA:	 float = 0.18	# CHANCE POR CELULA DA MOLDURA DA SALA
const HOLE_CHANCE_CROSSFIRE: float = 0.10	# CHANCE POR CELULA LATERAL DO CORREDOR

# ----- FOGO CRUZADO -----
const CROSSFIRE_MIN_WIDTH:	int = 5
const SHOOTER_SPACING_MIN:	int = 3
const SHOOTER_SPACING_MAX:	int = 4
const CROSSFIRE_DOUBLE_CHANCE: float = 0.3
const SHOOTER_ORIENT_FROM_LEFT:		int = ORIENT_UP
const SHOOTER_ORIENT_FROM_RIGHT:	int = ORIENT_DOWN

func _depth_min() -> int:	return 13
func _depth_max() -> int:	return 17
func _width_min() -> int:	return 5
func _width_max() -> int:	return 7
func type_name() -> String:	return "risco"

func build() -> Dictionary:
	var shape: int = rng.randi_range(0, 1)

	match shape:
		SHAPE_SKELETON_ARENA:	_build_skeleton_arena()
		SHAPE_CROSSFIRE:		_build_crossfire()

	finalize()
	return get_result()

func _build_skeleton_arena() -> void:
	exit_x = entry_x	# LINHA RETA PELO MEIO

	var half_room: int = ARENA_RING_RADIUS + ARENA_ROOM_MARGIN
	var room_side: int = half_room * 2 + 1
	var corridor_total: int = depth - room_side
	var corridor_in: int = corridor_total / 2

	# CORREDOR DE ENTRADA (NO CENTRO)
	for step in range(corridor_in):
		carve_main(entry_x, chunk_start_z - step)

	# SALA CENTRADA NO CAMINHO
	var arena_cx: int = entry_x
	var room_first_z: int = chunk_start_z - corridor_in
	var room_last_z: int = room_first_z - room_side + 1
	var arena_cz: int = room_first_z - room_side / 2
	carve_rect(arena_cx - half_room, arena_cx + half_room, room_last_z, room_first_z)

	# MAIN PATH ATRAVESSA A SALA PELO MEIO
	for z_idx in range(room_side):
		mark_main(entry_x, room_first_z - z_idx)

	# GUARDIAO SORTEADO
	var guardian: int = rng.randi_range(0, 2)
	match guardian:
		GUARD_SKELETON:
			var side: int = -1 if rng.randi_range(0, 1) == 0 else 1
			add_hazard(arena_cx + side * ARENA_GUARD_OFFSET, arena_cz, SKELETON)
		GUARD_FIRE_CIRCLE:
			var side: int = -1 if rng.randi_range(0, 1) == 0 else 1
			add_hazard(arena_cx + side * ARENA_GUARD_OFFSET, arena_cz, FIRE_CIRCLE)
		GUARD_FIRE_HORIZ:
			_place_fire_horizontals(arena_cx, arena_cz)

	# ANEL FECHADO DE SPIKES COM FORMATO SORTEADO.
	var ring_shape: int = rng.randi_range(0, 2)
	for cell in _ring_cells(ring_shape, arena_cx, arena_cz, ARENA_RING_RADIUS):
		_try_add_object(cell.x, cell.y, SPIKE, ORIENT_DOWN)

	# BURACOS.
	for dx in range(-half_room, half_room + 1):
		for dz in range(-half_room, half_room + 1):
			if max(abs(dx), abs(dz)) != half_room:
				continue
			var hx: int = arena_cx + dx
			var hz: int = arena_cz + dz
			if has_object(hx, hz):
				continue
			if rng.randf() < HOLE_CHANCE_ARENA:
				erase_floor(hx, hz)

	# CORREDOR DE SAIDA (NO CENTRO)
	for step in range(corridor_in + room_side, depth):
		carve_main(exit_x, chunk_start_z - step)

func _ring_cells(shape: int, cx: int, cz: int, r: int) -> Array:
	var cells: Array = []
	for dx in range(-r, r + 1):
		for dz in range(-r, r + 1):
			var on_ring: bool = false
			match shape:
				RING_SQUARE:	on_ring = max(abs(dx), abs(dz)) == r
				RING_DIAMOND:	on_ring = abs(dx) + abs(dz) == r
				RING_CIRCLE:	on_ring = abs(dx * dx + dz * dz - r * r) <= 1
			if on_ring:
				cells.append(Vector2i(cx + dx, cz + dz))
	return cells

func _place_fire_horizontals(cx: int, cz: int) -> void:
	var slots: Array = []
	for dx in [-2, -1, 1, 2]:
		for dz in [-1, 0, 1]:
			slots.append({"x": cx + dx, "z": cz + dz, "orient": ORIENT_LEFT})
	for dx in [-1, 1]:
		for dz in [-2, -1, 0, 1, 2]:
			slots.append({"x": cx + dx, "z": cz + dz, "orient": ORIENT_DOWN})

	_shuffle(slots)

	var placed: int = 0
	for slot in slots:
		if placed >= NUM_FIRE_HORIZ:
			break
		if add_hazard(slot["x"], slot["z"], FIRE_HORIZONTAL, slot["orient"]):
			placed += 1

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func _build_crossfire() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)
	var local_width: int = max(width, CROSSFIRE_MIN_WIDTH)
	var half_w: int = local_width / 2

	# CORREDOR LARGO COM MAIN PATH CENTRAL
	for step in range(depth):
		var center_x: int = interpolated_x(step)
		var z: int = chunk_start_z - step
		for w_off in range(-half_w, half_w + 1):
			carve_floor(center_x + w_off, z)
		mark_main(center_x, z)

	var side: int = -1 if rng.randi_range(0, 1) == 0 else 1
	var step_i: int = 2 + rng.randi_range(0, 1)
	while step_i < depth - 2:
		var z: int = chunk_start_z - step_i
		var center_x: int = interpolated_x(step_i)
		if rng.randf() < CROSSFIRE_DOUBLE_CHANCE:
			add_hazard(center_x - half_w, z, ONE_FIRE_SHOOTER, SHOOTER_ORIENT_FROM_LEFT)
			add_hazard(center_x + half_w, z, ONE_FIRE_SHOOTER, SHOOTER_ORIENT_FROM_RIGHT)
			step_i += rng.randi_range(SHOOTER_SPACING_MIN + 1, SHOOTER_SPACING_MAX + 1)
		else:
			var x: int = center_x + side * half_w
			var orient: int = SHOOTER_ORIENT_FROM_LEFT if side == -1 else SHOOTER_ORIENT_FROM_RIGHT
			add_hazard(x, z, ONE_FIRE_SHOOTER, orient)
			side = -side
			step_i += rng.randi_range(SHOOTER_SPACING_MIN, SHOOTER_SPACING_MAX)

	for step in range(1, depth - 1):
		var center_x: int = interpolated_x(step)
		var z: int = chunk_start_z - step
		for w_off in range(-half_w, half_w + 1):
			if w_off == 0:
				continue
			var x: int = center_x + w_off
			if has_object(x, z):
				continue
			if rng.randf() < HOLE_CHANCE_CROSSFIRE:
				erase_floor(x, z)
