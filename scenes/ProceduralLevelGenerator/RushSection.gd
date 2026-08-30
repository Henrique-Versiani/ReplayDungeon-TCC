extends BaseSection
class_name RushSection

const SHAPE_FIELD:		int = 0
const SHAPE_BRIDGE:		int = 1
const FIELD_WEIGHT:		int = 7

# ----- FEATURES -----
const FEAT_BOXES:		int = 0
const FEAT_GAUNTLET:	int = 1
const FEAT_HOLES:		int = 2
const FEAT_FIRE:		int = 3
const W_BOXES:			int = 4
const W_GAUNTLET:		int = 3
const W_HOLES:			int = 2
const W_FIRE:			int = 2

# ----- CORREDOR DE SPIKES -----
const GAUNTLET_MIN:		int = 4
const GAUNTLET_MAX:		int = 6

const BUFFER_STEPS:		int = 2
const SHIFT_CHANCE:		float = 0.35
const MIN_TURNS:		int = 2
const WEAVE_ATTEMPTS:	int = 8
const HOLE_CHANCE:		float = 0.7

# ----- CLUSTER DE CAIXAS -----
const CLUSTER_ROWS_MIN:		int = 3
const CLUSTER_ROWS_MAX:		int = 4
const CLUSTER_DENS_MIN:		float = 0.55
const CLUSTER_DENS_MAX:		float = 0.65
const CLUSTER_MIN_BOXES:	int = 4
const CLUSTER_MIN_PUSHES:	int = 2
const CLUSTER_ATTEMPTS:		int = 40
const MAX_SOLVER_STATES:	int = 6000
const MAX_SOLVER_PUSHES:	int = 8

const FIRE_ORIENT_HORIZONTAL:	int = ORIENT_LEFT
const SPIKES_ON_STABLE_FLOOR:	bool = true
const DIRS: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

func _depth_min() -> int:	return 12
func _depth_max() -> int:	return 16
func _width_min() -> int:	return 3
func _width_max() -> int:	return 3
func type_name() -> String:	return "rush"

func build() -> Dictionary:
	exit_x = entry_x
	var half_w: int = width / 2
	var zone_len: int = depth - 2 * BUFFER_STEPS
	var offsets: Array = _weave_offsets(zone_len, half_w)

	_carve_buffer(0, half_w)

	if rng.randi_range(0, 9) < FIELD_WEIGHT:
		_build_field(offsets, half_w)
	else:
		_build_bridge(offsets)

	_carve_buffer(depth - BUFFER_STEPS, half_w)

	finalize()
	return get_result()

func _carve_buffer(start_step: int, half_w: int) -> void:
	for step in range(start_step, start_step + BUFFER_STEPS):
		var z: int = chunk_start_z - step
		for w_off in range(-half_w, half_w + 1):
			carve_floor(entry_x + w_off, z)
		mark_main(entry_x, z)

func _weave_offsets(zone_len: int, half_w: int) -> Array:
	for attempt in range(WEAVE_ATTEMPTS):
		var off: Array = [0]
		for r in range(1, zone_len):
			var remaining: int = zone_len - 1 - r
			var cur: int = off[off.size() - 1]
			var nxt: int = cur
			if abs(cur) >= remaining + 1:
				nxt = cur - (1 if cur > 0 else -1)
			elif abs(cur) == remaining:
				if rng.randf() < 0.6:
					nxt = cur - (1 if cur > 0 else -1)
			elif rng.randf() < SHIFT_CHANCE:
				var d: int = -1 if rng.randf() < 0.5 else 1
				nxt = clamp(cur + d, -half_w, half_w)
				if abs(nxt) > remaining:
					nxt = cur
			off.append(nxt)
		off[off.size() - 1] = 0

		var turns: int = 0
		for i in range(1, off.size()):
			if off[i] != off[i - 1]:
				turns += 1
		if turns >= MIN_TURNS:
			return off

	var off: Array = []
	for i in range(zone_len):
		off.append(0)
	var mid: int = zone_len / 2
	for i in range(mid, min(mid + 2, zone_len - 1)):
		off[i] = 1
	return off

func _mark_route(offsets: Array) -> void:
	for i in range(offsets.size()):
		var z: int = chunk_start_z - (BUFFER_STEPS + i)
		carve_main(entry_x + offsets[i], z)
		if i > 0 and offsets[i] != offsets[i - 1]:
			carve_main(entry_x + offsets[i - 1], z)

func _build_field(offsets: Array, half_w: int) -> void:
	var zone_len: int = offsets.size()
	var stable_cells: Array = []

	# 1) CHAO NORMAL + ROTA
	for i in range(zone_len):
		var z: int = chunk_start_z - (BUFFER_STEPS + i)
		for w_off in range(-half_w, half_w + 1):
			carve_floor(entry_x + w_off, z)
	_mark_route(offsets)

	var row_i: int = rng.randi_range(1, 2)
	while row_i <= zone_len - 3:
		match _pick_feature():
			FEAT_BOXES:
				var rows_used: int = _place_box_cluster(row_i, zone_len)
				row_i += rows_used + 2
			FEAT_GAUNTLET:
				row_i += _place_spike_gauntlet(row_i, zone_len, half_w, stable_cells)
			FEAT_HOLES:
				var z: int = chunk_start_z - (BUFFER_STEPS + row_i)
				for w_off in range(-half_w, half_w + 1):
					var x: int = entry_x + w_off
					if is_main_path(x, z):
						continue
					if has_object(x, z):
						continue
					if rng.randf() < HOLE_CHANCE:
						erase_floor(x, z)
				row_i += rng.randi_range(2, 3)
			FEAT_FIRE:
				var z: int = chunk_start_z - (BUFFER_STEPS + row_i)
				_try_add_object(entry_x, z, FIRE_HORIZONTAL, FIRE_ORIENT_HORIZONTAL)
				row_i += 3

	for i in range(zone_len):
		var z: int = chunk_start_z - (BUFFER_STEPS + i)
		for w_off in range(-half_w, half_w + 1):
			var x: int = entry_x + w_off
			if has_floor(x, z):
				replace_floor(x, z, PLATFORM_FALLING)

	if SPIKES_ON_STABLE_FLOOR:
		for cell in stable_cells:
			replace_floor(cell.x, cell.y, floor_mesh)

func _pick_feature() -> int:
	var total: int = W_BOXES + W_GAUNTLET + W_HOLES + W_FIRE
	var roll: int = rng.randi_range(0, total - 1)
	if roll < W_BOXES:
		return FEAT_BOXES
	if roll < W_BOXES + W_GAUNTLET:
		return FEAT_GAUNTLET
	if roll < W_BOXES + W_GAUNTLET + W_HOLES:
		return FEAT_HOLES
	return FEAT_FIRE

func _place_spike_gauntlet(start_row: int, zone_len: int, half_w: int, stable_cells: Array) -> int:
	var i: int = max(start_row, 1)
	var available: int = zone_len - 1 - i
	if available < GAUNTLET_MIN:
		return 1

	var run: int = min(rng.randi_range(GAUNTLET_MIN, GAUNTLET_MAX), available)
	var z_wait: int = chunk_start_z - (BUFFER_STEPS + i - 1)
	for w_off in range(-half_w, half_w + 1):
		stable_cells.append(Vector2i(entry_x + w_off, z_wait))

	for k in range(run):
		var z: int = chunk_start_z - (BUFFER_STEPS + i + k)
		for w_off in range(-half_w, half_w + 1):
			var x: int = entry_x + w_off
			if _try_add_object(x, z, SPIKE, ORIENT_DOWN):
				stable_cells.append(Vector2i(x, z))

	return (i - start_row) + run + 1

func _place_box_cluster(start_row: int, zone_len: int) -> int:
	var max_rows: int = min(CLUSTER_ROWS_MAX, zone_len - start_row - 2)
	if max_rows < CLUSTER_ROWS_MIN:
		return 1

	for attempt in range(CLUSTER_ATTEMPTS):
		var rows: int = rng.randi_range(CLUSTER_ROWS_MIN, max_rows)
		var density: float = CLUSTER_DENS_MIN + rng.randf() * (CLUSTER_DENS_MAX - CLUSTER_DENS_MIN)

		var boxes: Dictionary = {}
		for r in range(rows):
			for x in [-1, 0, 1]:
				if rng.randf() < density:
					boxes[Vector2i(x, r)] = true

		if boxes.size() < CLUSTER_MIN_BOXES:
			continue
		if _cluster_min_pushes(rows, boxes) < CLUSTER_MIN_PUSHES:
			continue

		for cell in boxes.keys():
			var z: int = chunk_start_z - (BUFFER_STEPS + start_row + cell.y)
			_try_add_object(entry_x + cell.x, z, GOLEM, ORIENT_DOWN)
		return rows

	var z_fb: int = chunk_start_z - (BUFFER_STEPS + start_row)
	for x in [-1, 0, 1]:
		_try_add_object(entry_x + x, z_fb, GOLEM, ORIENT_DOWN)
	return 1

func _cluster_min_pushes(rows: int, boxes: Dictionary) -> int:
	var start_p: Vector2i = Vector2i(0, -1)
	var seen: Dictionary = {_state_key(start_p, boxes): true}
	var frontier: Array = [[start_p, boxes]]
	var pushes: int = 0

	while pushes <= MAX_SOLVER_PUSHES:
		if seen.size() > MAX_SOLVER_STATES:
			return -1

		var queue: Array = frontier.duplicate()
		var closure: Array = []
		var head: int = 0
		while head < queue.size():
			var cur: Array = queue[head]
			head += 1
			closure.append(cur)

			var p: Vector2i = cur[0]
			var bx: Dictionary = cur[1]
			if p.y >= rows:
				return pushes

			for d in DIRS:
				var np: Vector2i = p + d
				if abs(np.x) > 1 or np.y < -1 or np.y > rows:
					continue
				if bx.has(np):
					continue
				var mkey: String = _state_key(np, bx)
				if seen.has(mkey):
					continue
				seen[mkey] = true
				queue.append([np, bx])

		var next_frontier: Array = []
		for cur in closure:
			var p: Vector2i = cur[0]
			var bx: Dictionary = cur[1]
			for d in DIRS:
				var np: Vector2i = p + d
				if abs(np.x) > 1 or np.y < -1 or np.y > rows:
					continue
				if not bx.has(np):
					continue
				var nb: Vector2i = np + d
				if nb.y < -1 or nb.y > rows:
					continue
				var nbx: Dictionary = bx.duplicate()
				nbx.erase(np)
				if abs(nb.x) > 1:
					pass
				elif bx.has(nb):
					continue
				else:
					nbx[nb] = true
				var pkey: String = _state_key(np, nbx)
				if seen.has(pkey):
					continue
				seen[pkey] = true
				next_frontier.append([np, nbx])

		if next_frontier.is_empty():
			return -1
		frontier = next_frontier
		pushes += 1

	return -1

func _state_key(p: Vector2i, boxes: Dictionary) -> String:
	var parts: Array = []
	for b in boxes.keys():
		parts.append("%d.%d" % [b.x, b.y])
	parts.sort()
	return "%d.%d|%s" % [p.x, p.y, ",".join(parts)]

func _build_bridge(offsets: Array) -> void:
	_mark_route(offsets)

	var zone_len: int = offsets.size()
	var stable_cells: Array = []

	var candidates: Array = []
	for i in range(1, zone_len - 1):
		if offsets[i] == offsets[i - 1]:
			candidates.append(i)
	_shuffle(candidates)

	var used: Array = []
	var n_traps: int = rng.randi_range(1, 2)
	for i in candidates:
		if used.size() >= n_traps:
			break
		var too_close: bool = false
		for j in used:
			if abs(i - j) < 3:
				too_close = true
				break
		if too_close:
			continue
		var z: int = chunk_start_z - (BUFFER_STEPS + i)
		var x: int = entry_x + offsets[i]
		if rng.randf() < 0.5:
			if _try_add_object(x, z, SPIKE, ORIENT_DOWN):
				stable_cells.append(Vector2i(x, z))
				used.append(i)
		else:
			if _try_add_object(x, z, FIRE_HORIZONTAL, FIRE_ORIENT_HORIZONTAL):
				used.append(i)

	for i in range(zone_len):
		var z: int = chunk_start_z - (BUFFER_STEPS + i)
		replace_floor(entry_x + offsets[i], z, PLATFORM_FALLING)
		if i > 0 and offsets[i] != offsets[i - 1]:
			replace_floor(entry_x + offsets[i - 1], z, PLATFORM_FALLING)

	if SPIKES_ON_STABLE_FLOOR:
		for cell in stable_cells:
			replace_floor(cell.x, cell.y, floor_mesh)

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp
