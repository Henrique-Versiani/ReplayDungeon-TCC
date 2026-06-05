extends BaseSection
class_name TransicaoSection

const SHAPE_STRAIGHT:	int = 0
const SHAPE_NARROW:		int = 1
const SHAPE_CURVED:		int = 2
const SHAPE_SQUARE:		int = 3
const SHAPE_ZIGZAG:		int = 4
const SHAPE_L:			int = 5

const CHANCE_FALLING_PLATFORMS:	float = 0.35

func _depth_min() -> int:	return 6
func _depth_max() -> int:	return 14
func _width_min() -> int:	return 1
func _width_max() -> int:	return 3
func type_name() -> String:	return "transicao"


func build() -> Dictionary:
	var shape: int = rng.randi_range(0, 5)

	match shape:
		SHAPE_STRAIGHT:	_build_straight()
		SHAPE_NARROW:	_build_narrow()
		SHAPE_CURVED:	_build_curved()
		SHAPE_SQUARE:	_build_square()
		SHAPE_ZIGZAG:	_build_zigzag()
		SHAPE_L:		_build_l()

	_maybe_add_falling_platforms()
	finalize()

	return get_result()

# FORMATO 0: CORREDOR RETO
func _build_straight() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)
	var half_w: int = width / 2

	for step in range(depth):
		var center_x: int = interpolated_x(step)
		var z: int = chunk_start_z - step

		for w_off in range(-half_w, half_w + 1):
			carve_floor(center_x + w_off, z)
		mark_main(center_x, z)

# FORMATO 1: CORREDOR ESTREITO
func _build_narrow() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)

	for step in range(depth):
		var center_x: int = interpolated_x(step)
		carve_main(center_x, chunk_start_z - step)

# FORMATO 2: CORREDOR EM "S"
func _build_curved() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)

	var max_amp: int = max(1, (depth - 1) / 3)
	var amplitude: int = rng.randi_range(1, min(2, max_amp))
	var curve_dir: int = -1 if rng.randi_range(0, 1) == 0 else 1
	var half_w: int = width / 2

	var prev_center_x: int = entry_x

	for step in range(depth):
		var t: float = float(step) / float(max(depth - 1, 1))
		var base_x: int = int(round(lerp(float(entry_x), float(exit_x), t)))
		var offset: int = int(round(sin(t * PI) * float(amplitude) * float(curve_dir)))
		var center_x: int = base_x + offset

		if step > 0:
			center_x = clamp(center_x, prev_center_x - 1, prev_center_x + 1)
		prev_center_x = center_x

		var z: int = chunk_start_z - step
		for w_off in range(-half_w, half_w + 1):
			carve_floor(center_x + w_off, z)
		mark_main(center_x, z)

# FORMATO 3: SALA QUADRADA NO MEIO
func _build_square() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)

	var corridor_in_len: int = 2
	var max_room_side: int = max(2, depth - corridor_in_len - 2)
	var room_side: int = min(rng.randi_range(3, 4), max_room_side)
	var corridor_out_start: int = corridor_in_len + room_side
	var half: int = (room_side - 1) / 2

	for step in range(corridor_in_len):
		carve_main(entry_x, chunk_start_z - step)

	var room_first_z: int = chunk_start_z - corridor_in_len
	var room_last_z: int = room_first_z - (room_side - 1)
	carve_rect(entry_x - half, entry_x + half, room_last_z, room_first_z)

	for z_idx in range(room_side):
		mark_main(entry_x, room_first_z - z_idx)

	if exit_x != entry_x:
		mark_main(exit_x, room_last_z)

	for step in range(corridor_out_start, depth):
		carve_main(exit_x, chunk_start_z - step)

# FORMATO 4: ZIGZAG
func _build_zigzag() -> void:
	exit_x = entry_x + rng.randi_range(-1, 1)

	var swing: int = rng.randi_range(2, 3)
	var first_dir: int = -1 if rng.randi_range(0, 1) == 0 else 1

	var path_xs: Array = [entry_x]
	var current_x: int = entry_x
	var direction: int = first_dir
	var step: int = 1
	var swings_remaining: int = depth - 1
	var phase: int = 0

	while step < depth:
		var lateral_count: int = swing if phase == 0 else swing * 2
		lateral_count = min(lateral_count, swings_remaining)

		for _i in range(lateral_count):
			if step >= depth:
				break
			current_x += direction
			path_xs.append(current_x)
			step += 1

		swings_remaining -= lateral_count
		direction = -direction
		phase += 1

	while path_xs[-1] != exit_x and path_xs.size() < depth:
		current_x = path_xs[-1]
		if current_x < exit_x:		current_x += 1
		elif current_x > exit_x:	current_x -= 1
		path_xs.append(current_x)

	while path_xs.size() < depth:
		path_xs.append(path_xs[-1])

	exit_x = path_xs[depth - 1]

	for s in range(depth):
		carve_main(path_xs[s], chunk_start_z - s)

# FORMATO 5: EM "L"
func _build_l() -> void:
	var l_distance: int = rng.randi_range(2, 3)
	var l_side: int = -l_distance if rng.randi_range(0, 1) == 0 else l_distance
	var direction: int = sign(l_side)

	var min_required: int = l_distance + 2
	if depth < min_required:
		_build_straight()
		return

	exit_x = entry_x + l_side

	var remaining: int = depth - l_distance
	var vertical_in: int = remaining / 2

	for step in range(vertical_in):
		carve_main(entry_x, chunk_start_z - step)

	var corner_start_z: int = chunk_start_z - vertical_in
	var corner_end_z: int = corner_start_z - (l_distance - 1)
	var x_lo: int = min(entry_x, exit_x)
	var x_hi: int = max(entry_x, exit_x)
	carve_rect(x_lo, x_hi, corner_end_z, corner_start_z)

	for i in range(l_distance):
		var diag_x: int = entry_x + direction * i
		var diag_z: int = corner_start_z - i
		mark_main(diag_x, diag_z)

	var vertical_out_start: int = vertical_in + l_distance
	for step in range(vertical_out_start, depth):
		carve_main(exit_x, chunk_start_z - step)

func _maybe_add_falling_platforms() -> void:
	if rng.randf() > CHANCE_FALLING_PLATFORMS:
		return

	var entry_z: int = chunk_start_z
	var exit_z: int = chunk_start_z - depth + 1
	var candidates: Array = []
	for cell in get_main_path_cells():
		if cell.z != entry_z and cell.z != exit_z:
			candidates.append(cell)

	if candidates.size() < 2:
		return

	var n: int = min(rng.randi_range(1, 2), candidates.size())
	for _i in range(n):
		var idx: int = rng.randi() % candidates.size()
		var cell: Vector3i = candidates[idx]
		replace_floor(cell.x, cell.z, PLATFORM_FALLING)
		candidates.remove_at(idx)