extends RefCounted
class_name BaseSection

# ----- MESHES -----
const PLATFORM_FALLING:	int = 0
const COIN:				int = 2
const WEB:				int = 3
const CHEST:			int = 4
const SAW:				int = 6
const SPINNER_DOUBLE:	int = 7
const ARROW_SHOOTER:	int = 8
const SLIME_SHOOTER:	int = 9
const SPIKE:			int = 10
const PUSHER:			int = 12
const BAT_ON_SPOT:		int = 13
const BAT_CIRCLE:		int = 14
const SKELETON:			int = 15
const FIRE_HORIZONTAL:	int = 16
const FIRE_CIRCLE:		int = 17
const DIAMOND:			int = 18
const STAR:				int = 19
const GOLEM:			int = 20
const FIRE_SHOOTER:		int = 21
const ONE_FIRE_SHOOTER:	int = 22
const ONE_SLIME_SHOOTER: int = 23

# ----- ORIENTACOES -----
const ORIENT_DOWN:	int = 0
const ORIENT_LEFT:	int = 22
const ORIENT_UP:	int = 10
const ORIENT_RIGHT:	int = 16

# ----- POOLS DE MESHES POR CATEGORIA -----
const LETHAL_TRAPS:			Array = [SPIKE, SAW, SPINNER_DOUBLE]
const RANGED_TRAPS:			Array = [ARROW_SHOOTER, SLIME_SHOOTER, FIRE_SHOOTER, ONE_FIRE_SHOOTER, ONE_SLIME_SHOOTER]
const STATIC_ENEMIES:		Array = [BAT_ON_SPOT, FIRE_HORIZONTAL, FIRE_CIRCLE]
const MOVING_ENEMIES:		Array = [SKELETON, BAT_CIRCLE]
const PUSHABLE_OBSTACLES:	Array = [GOLEM]
const NON_LETHAL_HAZARDS:	Array = [WEB, PUSHER]
const REWARDS_GROUND:		Array = [COIN, DIAMOND, STAR]

var rng:			RandomNumberGenerator
var entry_x:		int
var chunk_start_z:	int
var depth:			int
var width:			int
var floor_y:		int
var floor_mesh:		int
var exit_x:			int

var floor_cells:	Dictionary = {}
var object_cells:	Dictionary = {}
var main_path:		Dictionary = {}

func _init(
	p_entry_x: int,
	p_chunk_start_z: int,
	base_seed: int,
	chunk_id: int,
	p_floor_y: int,
	p_floor_mesh: int
):
	rng = RandomNumberGenerator.new()
	rng.seed = base_seed + chunk_id * 7919
	entry_x = p_entry_x
	chunk_start_z = p_chunk_start_z
	floor_y = p_floor_y
	floor_mesh = p_floor_mesh
	depth = rng.randi_range(_depth_min(), _depth_max())
	width = rng.randi_range(_width_min(), _width_max())
	exit_x = entry_x

func _depth_min() -> int:	return 6
func _depth_max() -> int:	return 10
func _width_min() -> int:	return 2
func _width_max() -> int:	return 3
func type_name() -> String:	return "base"

func build() -> Dictionary:
	push_error("BaseSection.build() must be overridden by subclass")
	return get_result()

func carve_floor(x: int, z: int) -> void:
	var cell: Vector3i = Vector3i(x, floor_y, z)
	floor_cells[_key(cell)] = {"cell": cell, "mesh": floor_mesh, "orientation": ORIENT_DOWN}

func carve_main(x: int, z: int) -> void:
	carve_floor(x, z)
	mark_main(x, z)

func mark_main(x: int, z: int) -> void:
	var cell: Vector3i = Vector3i(x, floor_y, z)
	main_path[_key(cell)] = cell

func replace_floor(x: int, z: int, new_mesh: int) -> void:
	var cell: Vector3i = Vector3i(x, floor_y, z)
	floor_cells[_key(cell)] = {"cell": cell, "mesh": new_mesh, "orientation": ORIENT_DOWN}

func erase_floor(x: int, z: int) -> void:
	"""
	REMOVE CHAO DA POSICAO (CRIA BURACO).
	NAO REMOVE SE FOR MAIN PATH.
	"""
	var key: String = _key(Vector3i(x, floor_y, z))
	if main_path.has(key):
		return
	floor_cells.erase(key)

func add_decoration(x: int, z: int, mesh: int, orientation: int = ORIENT_DOWN) -> bool:
	return _try_add_object(x, z, mesh, orientation)

func add_hazard(x: int, z: int, mesh: int, orientation: int = ORIENT_DOWN) -> bool:
	if is_main_path(x, z):
		return false
	return _try_add_object(x, z, mesh, orientation)

func add_pushable(x: int, z: int, orientation: int = ORIENT_DOWN) -> bool:
	return _try_add_object(x, z, GOLEM, orientation)

func add_chest(x: int, z: int, orientation: int = ORIENT_DOWN) -> bool:
	"""
	COLOCA UM BAU NA POSICAO.
	"""
	var key: String = _key(Vector3i(x, floor_y, z))
	if not floor_cells.has(key):
		return false

	clear_object(x, z)

	var cell: Vector3i = Vector3i(x, floor_y, z)
	floor_cells[key] = {"cell": cell, "mesh": CHEST, "orientation": orientation}
	return true

func _try_add_object(x: int, z: int, mesh: int, orientation: int) -> bool:
	var floor_key: String = _key(Vector3i(x, floor_y, z))
	if not floor_cells.has(floor_key):
		return false

	if floor_cells[floor_key]["mesh"] != floor_mesh:
		return false
	var obj_cell: Vector3i = Vector3i(x, floor_y + 1, z)
	var obj_key: String = _key(obj_cell)
	if object_cells.has(obj_key):
		return false
	object_cells[obj_key] = {"cell": obj_cell, "mesh": mesh, "orientation": orientation}
	return true

func clear_object(x: int, z: int) -> void:
	var obj_key: String = _key(Vector3i(x, floor_y + 1, z))
	object_cells.erase(obj_key)

func ensure_entry_clear() -> void:
	var cell: Vector3i = Vector3i(entry_x, floor_y, chunk_start_z)
	floor_cells[_key(cell)] = {"cell": cell, "mesh": floor_mesh, "orientation": ORIENT_DOWN}
	mark_main(entry_x, chunk_start_z)
	clear_object(entry_x, chunk_start_z)

func ensure_exit_clear() -> void:
	var exit_z: int = chunk_start_z - depth + 1
	var cell: Vector3i = Vector3i(exit_x, floor_y, exit_z)
	floor_cells[_key(cell)] = {"cell": cell, "mesh": floor_mesh, "orientation": ORIENT_DOWN}
	mark_main(exit_x, exit_z)
	clear_object(exit_x, exit_z)

func ensure_4dir_connectivity() -> void:
	"""
	GARANTE QUE O MAIN_PATH SEJA ATRAVESSAVEL COM MOVIMENTO EM 4 DIRECOES.
	"""
	var by_z: Dictionary = {}
	for cell in main_path.values():
		if not by_z.has(cell.z):
			by_z[cell.z] = []
		by_z[cell.z].append(cell.x)

	var zs: Array = by_z.keys()
	zs.sort()
	zs.reverse()

	for i in range(zs.size() - 1):
		var z_upper: int = zs[i]
		var z_lower: int = zs[i + 1]
		if z_upper - z_lower != 1:
			continue

		var xs_upper: Array = by_z[z_upper]
		var xs_lower: Array = by_z[z_lower]
		var best_xu: int = xs_upper[0]
		var best_xl: int = xs_lower[0]
		var best_dist: int = abs(best_xu - best_xl)
		for xu in xs_upper:
			for xl in xs_lower:
				var d: int = abs(xu - xl)
				if d < best_dist:
					best_dist = d
					best_xu = xu
					best_xl = xl

		if best_dist == 0:
			continue

		if has_floor(best_xu, z_lower) or has_floor(best_xl, z_upper):
			continue

		carve_main(best_xu, z_lower)


func verify_path_connectivity() -> bool:
	"""
	FAZ BFS DA ENTRADA ATE A SAIDA USANDO floor_cells COMO GRAFO.
	RETORNA true SE A SAIDA E ALCANCAVEL A PARTIR DA ENTRADA EM 4 DIRECOES.
	"""
	var start: Vector3i = Vector3i(entry_x, floor_y, chunk_start_z)
	var goal: Vector3i = Vector3i(exit_x, floor_y, chunk_start_z - depth + 1)

	if not has_floor(start.x, start.z) or not has_floor(goal.x, goal.z):
		return false

	var visited: Dictionary = {}
	var queue: Array = [start]
	visited[_key(start)] = true

	while not queue.is_empty():
		var current: Vector3i = queue.pop_front()
		if current.x == goal.x and current.z == goal.z:
			return true
		for delta in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			var n: Vector3i = current + delta
			var k: String = _key(n)
			if not visited.has(k) and has_floor(n.x, n.z):
				visited[k] = true
				queue.append(n)

	return false


func _emergency_carve_path() -> void:
	"""
	FALLBACK USADO QUANDO verify_path_connectivity() FALHA.
	ADICIONA O MINIMO NECESSARIO PARA CONECTAR, SEM DESTRUIR A
	ESTRUTURA EXISTENTE DA SECAO.
	"""
	push_warning("[%s] caminho nao atravessavel - aplicando carve emergencial" % type_name())

	var start: Vector3i = Vector3i(entry_x, floor_y, chunk_start_z)
	var goal: Vector3i = Vector3i(exit_x, floor_y, chunk_start_z - depth + 1)
	var reachable: Dictionary = {}
	var queue: Array = [start]
	reachable[_key(start)] = start

	while not queue.is_empty():
		var current: Vector3i = queue.pop_front()
		for delta in [Vector3i(1, 0, 0), Vector3i(-1, 0, 0), Vector3i(0, 0, 1), Vector3i(0, 0, -1)]:
			var n: Vector3i = current + delta
			var k: String = _key(n)
			if not reachable.has(k) and has_floor(n.x, n.z):
				reachable[k] = n
				queue.append(n)

	var closest: Vector3i = start
	var min_dist: int = abs(goal.x - start.x) + abs(goal.z - start.z)
	for cell in reachable.values():
		var d: int = abs(goal.x - cell.x) + abs(goal.z - cell.z)
		if d < min_dist:
			min_dist = d
			closest = cell

	var x_lo: int = min(closest.x, goal.x)
	var x_hi: int = max(closest.x, goal.x)
	for x in range(x_lo, x_hi + 1):
		carve_main(x, closest.z)

	var z_lo: int = min(closest.z, goal.z)
	var z_hi: int = max(closest.z, goal.z)
	for z in range(z_lo, z_hi + 1):
		carve_main(goal.x, z)


func finalize() -> void:
	"""
	APLICA TODAS AS GARANTIAS DE CONECTIVIDADE.
	"""
	ensure_4dir_connectivity()
	ensure_entry_clear()
	ensure_exit_clear()

	if not verify_path_connectivity():
		_emergency_carve_path()
		ensure_4dir_connectivity()
		ensure_entry_clear()
		ensure_exit_clear()

func is_main_path(x: int, z: int) -> bool:
	return main_path.has(_key(Vector3i(x, floor_y, z)))

func has_floor(x: int, z: int) -> bool:
	return floor_cells.has(_key(Vector3i(x, floor_y, z)))

func has_object(x: int, z: int) -> bool:
	return object_cells.has(_key(Vector3i(x, floor_y + 1, z)))

func get_main_path_cells() -> Array:
	return main_path.values()

func carve_corridor_z(x: int, z_start: int, z_end: int, mark_as_main: bool = false) -> void:
	var z_min: int = min(z_start, z_end)
	var z_max: int = max(z_start, z_end)
	for z in range(z_min, z_max + 1):
		if mark_as_main:
			carve_main(x, z)
		else:
			carve_floor(x, z)

func carve_corridor_x(z: int, x_start: int, x_end: int, mark_as_main: bool = false) -> void:
	var x_min: int = min(x_start, x_end)
	var x_max: int = max(x_start, x_end)
	for x in range(x_min, x_max + 1):
		if mark_as_main:
			carve_main(x, z)
		else:
			carve_floor(x, z)

func carve_rect(x_min: int, x_max: int, z_min: int, z_max: int) -> void:
	for x in range(x_min, x_max + 1):
		for z in range(z_min, z_max + 1):
			carve_floor(x, z)

func interpolated_x(step: int) -> int:
	var t: float = float(step) / float(max(depth - 1, 1))
	return int(round(lerp(float(entry_x), float(exit_x), t)))

func get_result() -> Dictionary:
	var cells: Array = []
	for cd in floor_cells.values():
		cells.append(cd)
	for od in object_cells.values():
		cells.append(od)
	return {
		"cells":	cells,
		"exit_x":	exit_x,
		"depth":	depth,
		"type":		type_name()
	}

func _key(cell: Vector3i) -> String:
	return str(cell.x) + "|" + str(cell.y) + "|" + str(cell.z)