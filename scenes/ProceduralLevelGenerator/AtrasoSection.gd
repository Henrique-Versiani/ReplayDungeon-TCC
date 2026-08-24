extends BaseSection
class_name AtrasoSection

const HALF_WIDTH:		int = 3			# COLUNAS
const BUFFER_STEPS:		int = 2			# LINHAS RETAS NAS EXTREMIDADES
const STRAIGHT_BIAS:	float = 0.1	# CHANCE DE CONTINUAR RETO (SEGMENTOS LONGOS)
const MAX_LEN_FACTOR:	float = 3.5		# COMPRIMENTO MAX DA COBRA = depth * ESTE FATOR
const MAX_ITERS:		int = 6000		# LIMITE DE BACKTRACKING ANTES DE FALHAR A TENTATIVA
const MAX_ATTEMPTS:		int = 8			# TENTATIVAS DE GERAR COBRA ANTES DO FALLBACK RETO

const SAW_MIN:			int = 1			# MINIMO DE SERRAS POR SECAO
const SAW_MAX:			int = 3			# MAXIMO DE SERRAS POR SECAO
const SAW_SPACING:		int = 3			# DISTANCIA MIN ENTRE CENTROS DE SERRAS (AO LONGO DO PATH)
const SAW_REACH:		int = 2			# QUANTOS BLOCOS A SERRA ANDA PARA CADA LADO
const SAW_ORIENT_HORIZONTAL: int = ORIENT_DOWN
const SAW_ORIENT_VERTICAL:	int = ORIENT_LEFT

func _depth_min() -> int:	return 13
func _depth_max() -> int:	return 18
func _width_min() -> int:	return 1		# NAO USADO (LARGURA EH HALF_WIDTH)
func _width_max() -> int:	return 1
func type_name() -> String:	return "atraso"

func build() -> Dictionary:
	exit_x = entry_x

	var full_path: Array = []
	for attempt in range(MAX_ATTEMPTS):
		full_path = _generate_snake()
		if not full_path.is_empty():
			break
	if full_path.is_empty():
		full_path = _straight_path()

	_carve_from_path(full_path)
	_place_saws(full_path)

	finalize()
	return get_result()

func _carve_from_path(full_path: Array) -> void:
	var path_set: Dictionary = {}
	for c in full_path:
		path_set[c] = true

	for c in full_path:
		carve_main(entry_x + c.x, chunk_start_z - c.y)

	for c in full_path:
		for n in _neighbors(c):
			if path_set.has(n):
				continue
			if n.y < 0 or n.y >= depth:
				continue
			if n.x < -HALF_WIDTH - 1 or n.x > HALF_WIDTH + 1:
				continue
			if _is_buffer_row(n.y):
				continue
			var ax: int = entry_x + n.x
			var az: int = chunk_start_z - n.y
			carve_floor(ax, az)
			add_decoration(ax, az, WEB)

func _is_buffer_row(row: int) -> bool:
	return row < BUFFER_STEPS or row >= depth - BUFFER_STEPS

func _place_saws(full_path: Array) -> void:
	var n_target: int = rng.randi_range(SAW_MIN, SAW_MAX)
	if n_target <= 0:
		return

	var path_set: Dictionary = {}
	for c in full_path:
		path_set[c] = true

	var saw_row_lo: int = 1
	var saw_row_hi: int = depth - 2
	var candidates: Array = []
	for i in range(BUFFER_STEPS + 1, full_path.size() - BUFFER_STEPS - 1):
		candidates.append(i)
	_rng_shuffle(candidates)

	var saw_reserved: Dictionary = {}
	var placed_indices: Array = []
	var placed: int = 0

	for i in candidates:
		if placed >= n_target:
			break

		var c: Vector2i = full_path[i]
		var prev: Vector2i = full_path[i - 1]
		var nxt: Vector2i = full_path[i + 1]
		var vertical: bool = prev.x == c.x and c.x == nxt.x and abs(prev.y - nxt.y) == 2
		var horizontal: bool = prev.y == c.y and c.y == nxt.y and abs(prev.x - nxt.x) == 2
		if not (vertical or horizontal):
			continue

		var too_close: bool = false
		for j in placed_indices:
			if abs(i - j) < SAW_SPACING:
				too_close = true
				break
		if too_close:
			continue

		var rail: Array = []
		var orient: int
		if vertical:
			orient = SAW_ORIENT_HORIZONTAL
			for d in range(-SAW_REACH, SAW_REACH + 1):
				rail.append(Vector2i(c.x + d, c.y))
		else:
			orient = SAW_ORIENT_VERTICAL
			for d in range(-SAW_REACH, SAW_REACH + 1):
				rail.append(Vector2i(c.x, c.y + d))

		if not _saw_rail_valid(rail, c, path_set, saw_reserved, saw_row_lo, saw_row_hi):
			continue

		for rc in rail:
			var ax: int = entry_x + rc.x
			var az: int = chunk_start_z - rc.y
			carve_floor(ax, az)
			clear_object(ax, az)
		add_decoration(entry_x + c.x, chunk_start_z - c.y, SAW, orient)

		for rc in rail:
			saw_reserved[rc] = true
			for nb in _neighbors(rc):
				saw_reserved[nb] = true

		placed_indices.append(i)
		placed += 1

func _saw_rail_valid(rail: Array, center: Vector2i, path_set: Dictionary,
					 saw_reserved: Dictionary, row_lo: int, row_hi: int) -> bool:
	for rc in rail:
		if rc.x < -HALF_WIDTH or rc.x > HALF_WIDTH:
			return false
		if rc.y < row_lo or rc.y > row_hi:
			return false
		if saw_reserved.has(rc):
			return false
		if rc == center:
			continue
		if path_set.has(rc):
			return false
		for nb in _neighbors(rc):
			if path_set.has(nb) and nb != center:
				return false
	return true

func _generate_snake() -> Array:
	var B: int = BUFFER_STEPS
	var D: int = depth

	var entry_buf: Array = []
	for r in range(B):
		entry_buf.append(Vector2i(0, r))
	var exit_buf: Array = []
	for r in range(D - B, D):
		exit_buf.append(Vector2i(0, r))

	var start: Vector2i = Vector2i(0, B)
	var goal: Vector2i = Vector2i(0, D - B - 1)
	if goal.y < start.y:
		return _straight_path()

	var interior_lo: int = B
	var interior_hi: int = D - B - 1
	var fixed: Dictionary = {}
	for c in entry_buf:
		fixed[c] = true
	for c in exit_buf:
		fixed[c] = true

	var max_len: int = int(D * MAX_LEN_FACTOR)

	var path: Array = [start]
	var path_set: Dictionary = {start: true}
	var stack: Array = [{
		"cell": start,
		"pred": Vector2i(0, B - 1),
		"opts": _ordered_neighbors(start, Vector2i(0, B - 1), goal)
	}]
	var iters: int = 0

	while not stack.is_empty():
		iters += 1
		if iters > MAX_ITERS:
			return []

		var frame: Dictionary = stack[stack.size() - 1]
		var cell: Vector2i = frame["cell"]
		if cell == goal:
			break

		var advanced: bool = false
		if path.size() <= max_len:
			var opts: Array = frame["opts"]
			while not opts.is_empty():
				var nxt: Vector2i = opts.pop_back()
				if not _in_interior(nxt, interior_lo, interior_hi):
					continue
				if path_set.has(nxt):
					continue
				if not _induced_ok(nxt, cell, path_set, fixed, goal, D, B):
					continue
				path.append(nxt)
				path_set[nxt] = true
				stack.append({
					"cell": nxt,
					"pred": cell,
					"opts": _ordered_neighbors(nxt, cell, goal)
				})
				advanced = true
				break

		if not advanced:
			stack.pop_back()
			if not path.is_empty():
				var dead: Vector2i = path.pop_back()
				path_set.erase(dead)

	if stack.is_empty() or path[path.size() - 1] != goal:
		return []

	var full: Array = []
	full.append_array(entry_buf)
	full.append_array(path)
	full.append_array(exit_buf)
	return full

func _induced_ok(c: Vector2i, pred: Vector2i, path_set: Dictionary,
				 fixed: Dictionary, goal: Vector2i, D: int, B: int) -> bool:
	for n in _neighbors(c):
		if n == pred:
			continue
		if path_set.has(n) or fixed.has(n):
			if c == goal and n == Vector2i(0, D - B):
				continue
			return false
	return true

func _ordered_neighbors(cell: Vector2i, pred: Vector2i, goal: Vector2i) -> Array:
	var nb: Array = _neighbors(cell)
	_rng_shuffle(nb)

	var rows_left: int = goal.y - cell.y
	if rows_left <= 2:
		nb.sort_custom(func(a, b): return _dist(a, goal) > _dist(b, goal))
		return nb

	var heading: Vector2i = Vector2i(cell.x - pred.x, cell.y - pred.y)
	var straight: Vector2i = Vector2i(cell.x + heading.x, cell.y + heading.y)
	if nb.has(straight) and rng.randf() < STRAIGHT_BIAS:
		nb.erase(straight)
		nb.append(straight)
	return nb

func _neighbors(c: Vector2i) -> Array:
	return [
		Vector2i(c.x + 1, c.y),
		Vector2i(c.x - 1, c.y),
		Vector2i(c.x, c.y + 1),
		Vector2i(c.x, c.y - 1)
	]

func _dist(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)

func _in_interior(c: Vector2i, lo: int, hi: int) -> bool:
	return c.x >= -HALF_WIDTH and c.x <= HALF_WIDTH and c.y >= lo and c.y <= hi

func _straight_path() -> Array:
	var full: Array = []
	for r in range(depth):
		full.append(Vector2i(0, r))
	return full

func _rng_shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp

func finalize() -> void:
	ensure_entry_clear()
	ensure_exit_clear()
	if not verify_path_connectivity():
		_emergency_carve_path()
