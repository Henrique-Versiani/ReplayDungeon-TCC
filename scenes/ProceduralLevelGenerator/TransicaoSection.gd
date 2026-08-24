extends BaseSection
class_name TransicaoSection

const SHAPE_STRAIGHT:	int = 0
const SHAPE_NARROW:		int = 1
const SHAPE_STEP:		int = 2
const SHAPE_S_BEND:		int = 3

# ----- MODIFICADOR: PLATAFORMA QUE CAI -----
const FALLING_CHANCE:		float = 0.2	# CHANCE DE TER UMA PLATAFORMA QUE CAI
const FALLING_MIN_DEPTH:	int = 6		# SO EM SECOES COM ESTA PROFUNDIDADE OU MAIS

func _depth_min() -> int:	return 4
func _depth_max() -> int:	return 8
func _width_min() -> int:	return 1
func _width_max() -> int:	return 3
func type_name() -> String:	return "transicao"

func build() -> Dictionary:
	var shape: int = rng.randi_range(0, 3)

	match shape:
		SHAPE_STRAIGHT:	_build_straight()
		SHAPE_NARROW:	_build_narrow()
		SHAPE_STEP:		_build_step()
		SHAPE_S_BEND:	_build_s_bend()

	_maybe_add_falling_platform()

	finalize()
	return get_result()

func _build_straight() -> void:
	exit_x = entry_x
	var half_w: int = width / 2
	for step in range(depth):
		var z: int = chunk_start_z - step
		for w_off in range(-half_w, half_w + 1):
			carve_floor(entry_x + w_off, z)
		mark_main(entry_x, z)

func _build_narrow() -> void:
	exit_x = entry_x
	for step in range(depth):
		carve_main(entry_x, chunk_start_z - step)


func _build_step() -> void:
	var dir: int = -1 if rng.randi_range(0, 1) == 0 else 1
	exit_x = entry_x + dir
	var turn_at: int = clamp(depth / 2, 1, depth - 2)

	for step in range(depth):
		var z: int = chunk_start_z - step
		if step < turn_at:
			carve_main(entry_x, z)
		elif step == turn_at:
			carve_main(entry_x, z)
			carve_main(exit_x, z)
		else:
			carve_main(exit_x, z)

func _build_s_bend() -> void:
	if depth < 6:
		_build_step()
		return

	var dir: int = -1 if rng.randi_range(0, 1) == 0 else 1
	var off_x: int = entry_x + dir
	exit_x = entry_x

	var turn_out: int = depth / 3
	var turn_back: int = (2 * depth) / 3

	for step in range(depth):
		var z: int = chunk_start_z - step
		if step < turn_out:
			carve_main(entry_x, z)
		elif step == turn_out:
			carve_main(entry_x, z)
			carve_main(off_x, z)
		elif step < turn_back:
			carve_main(off_x, z)
		elif step == turn_back:
			carve_main(off_x, z)
			carve_main(entry_x, z)
		else:
			carve_main(entry_x, z)


func _maybe_add_falling_platform() -> void:
	if depth < FALLING_MIN_DEPTH:
		return
	if rng.randf() >= FALLING_CHANCE:
		return

	var by_z: Dictionary = {}
	for cell in main_path.values():
		if not by_z.has(cell.z):
			by_z[cell.z] = []
		by_z[cell.z].append(cell.x)

	var first_z: int = chunk_start_z - 1
	var last_z: int = chunk_start_z - depth + 2

	var candidates: Array = []
	for z in by_z.keys():
		if z > first_z or z < last_z:
			continue
		if by_z[z].size() != 1:
			continue
		candidates.append(Vector2i(by_z[z][0], z))

	if candidates.is_empty():
		return

	var pick: Vector2i = candidates[rng.randi() % candidates.size()]
	replace_floor(pick.x, pick.y, PLATFORM_FALLING)