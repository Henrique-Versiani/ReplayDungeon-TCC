extends BaseSection
class_name EscolhaSection

const CHEST_FACE_BACK:	int = ORIENT_UP		# olha para -Z
const CHEST_FACE_FRONT:	int = ORIENT_DOWN	# olha para +Z
const CHEST_FACE_LEFT:	int = ORIENT_LEFT	# olha para -X
const CHEST_FACE_RIGHT:	int = ORIENT_RIGHT	# olha para +X

const BUFFER_STEPS:		int = 2

# ----- TRILHAS -----
const TRAIL_COUNT_MIN:	int = 1
const TRAIL_COUNT_MAX:	int = 2
const TRAIL_LEN_MIN:	int = 3		# PLATAFORMAS DA TRILHA
const TRAIL_LEN_MAX:	int = 3
const TRAIL_MAX_COL:	int = 2		# AFASTAMENTO LATERAL MAXIMO
const TRAIL_MAX_DZ:	int = 2		# DESVIO MAXIMO EM Z (TRILHA OCUPA 2*DZ+1 LINHAS)
const TRAIL_MIN_GAP:	int = 6		# LINHAS ENTRE TRILHAS
const OUTWARD_BIAS:	float = 0.65	# VIES DE CRESCIMENTO PARA LONGE DO CORREDOR
const TRAIL_ATTEMPTS:	int = 30	# TENTATIVAS DE GERAR UMA TRILHA VALIDA

# ----- CONTEUDO -----
const CHEST_CHANCE:		float = 0.60
const COIN_CHANCE:		float = 0.50	# ENTRE AS SEM BAU
const COIN_DENSITY:		float = 0.40

const DIRS: Array = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

# ================================================================
# OVERRIDES
# ================================================================

func _depth_min() -> int:	return 14
func _depth_max() -> int:	return 18
func _width_min() -> int:	return 1
func _width_max() -> int:	return 1
func type_name() -> String:	return "escolha"

# ================================================================
# BUILD
# ================================================================

func build() -> Dictionary:
	exit_x = entry_x

	for step in range(depth):
		carve_main(entry_x, chunk_start_z - step)

	_build_trails()

	finalize()
	return get_result()

# ================================================================
# TRILHAS
# ================================================================

func _build_trails() -> void:
	var rows: Array = []
	for r in range(BUFFER_STEPS + TRAIL_MAX_DZ, depth - BUFFER_STEPS - TRAIL_MAX_DZ):
		rows.append(r)
	_shuffle(rows)

	var target: int = rng.randi_range(TRAIL_COUNT_MIN, TRAIL_COUNT_MAX)
	var used_rows: Array = []
	var taken: Dictionary = {}

	for row in rows:
		if used_rows.size() >= target:
			break

		var too_close: bool = false
		for u in used_rows:
			if abs(row - u) < TRAIL_MIN_GAP:
				too_close = true
				break
		if too_close:
			continue

		var side: int = -1 if rng.randi_range(0, 1) == 0 else 1
		if _try_build_trail(row, side, taken):
			used_rows.append(row)


func _try_build_trail(row: int, side: int, taken: Dictionary) -> bool:
	var length: int = rng.randi_range(TRAIL_LEN_MIN, TRAIL_LEN_MAX)
	var result: Dictionary = _gen_trail(length)
	if result.is_empty():
		return false

	var path: Array = result["path"]
	var chest_local: Vector2i = result["chest"]

	# CONVERTE PARA O MUNDO E VALIDA LIMITES E COLISOES
	var world_path: Array = []
	for local in path:
		var w: Vector2i = _to_world(local, side, row)
		if w.y > chunk_start_z or w.y <= chunk_start_z - depth:
			return false
		if taken.has(w):
			return false
		world_path.append(w)

	var chest_world: Vector2i = _to_world(chest_local, side, row)
	if chest_world.y > chunk_start_z or chest_world.y <= chunk_start_z - depth:
		return false
	if taken.has(chest_world):
		return false

	# --- CONSTROI A TRILHA ---
	for w in world_path:
		carve_floor(w.x, w.y)
		replace_floor(w.x, w.y, PLATFORM_FALLING)
		taken[w] = true

	# --- CONTEUDO DO FIM ---
	var roll: float = rng.randf()
	if roll < CHEST_CHANCE:
		# add_chest TROCA O MESH DO CHAO: A CELULA PRECISA EXISTIR ANTES
		carve_floor(chest_world.x, chest_world.y)
		add_chest(chest_world.x, chest_world.y, _facing_towards(chest_local, path[path.size() - 1], side))
		taken[chest_world] = true
	elif roll < CHEST_CHANCE + COIN_CHANCE * (1.0 - CHEST_CHANCE):
		for w in world_path:
			if rng.randf() < COIN_DENSITY:
				add_decoration(w.x, w.y, COIN)
	# SENAO: A TRILHA NAO LEVA A NADA (SUSPENSE)

	return true

# ----------------------------------------------------------------
# GERA A TRILHA EM COORDENADAS LOCAIS (col, dz), col >= 1.
# REGRAS:
#   - comeca em (1, 0): unica celula que encosta no corredor
#   - nenhuma outra celula pode ter col == 1
#   - INDUZIDA: uma celula nova nao pode tocar nenhuma outra do
#     caminho alem da anterior (mantem 1 bloco de largura)
#   - vies para fora, para a trilha se afastar em vez de rondar perto
# RETORNA {"path": Array, "chest": Vector2i} OU {} SE FALHAR.
# ----------------------------------------------------------------
func _gen_trail(length: int) -> Dictionary:
	for attempt in range(TRAIL_ATTEMPTS):
		var start: Vector2i = Vector2i(1, 0)
		var path: Array = [start]
		var used: Dictionary = {start: true}
		var failed: bool = false

		while path.size() < length:
			var cur: Vector2i = path[path.size() - 1]
			var options: Array = _valid_steps(cur, used, start)
			if options.is_empty():
				failed = true
				break
			if rng.randf() < OUTWARD_BIAS:
				options = _keep_outermost(options)
			path.append(options[rng.randi() % options.size()])
			used[path[path.size() - 1]] = true

		if failed:
			continue

		# BAU: UMA CELULA ALEM DO FIM, TAMBEM INDUZIDA
		var last: Vector2i = path[path.size() - 1]
		var chest_opts: Array = _valid_steps(last, used, start, true)
		if chest_opts.is_empty():
			continue
		if rng.randf() < OUTWARD_BIAS:
			chest_opts = _keep_outermost(chest_opts)

		return {"path": path, "chest": chest_opts[rng.randi() % chest_opts.size()]}
	return {}

# ----------------------------------------------------------------
# PASSOS VALIDOS A PARTIR DE cur, RESPEITANDO A REGRA INDUZIDA.
# ----------------------------------------------------------------
func _valid_steps(cur: Vector2i, used: Dictionary, start: Vector2i, is_chest: bool = false) -> Array:
	var max_col: int = TRAIL_MAX_COL + (1 if is_chest else 0)
	var options: Array = []

	for d in DIRS:
		var n: Vector2i = cur + d
		if n.x < 2 and n != start:
			continue					# SO A PRIMEIRA CELULA NA COLUNA 1
		if n.x < 1 or n.x > max_col:
			continue
		if abs(n.y) > TRAIL_MAX_DZ:
			continue
		if used.has(n):
			continue

		# INDUZIDA: n nao pode tocar nenhuma celula do caminho alem de cur,
		# nem encostar no corredor (coluna 0)
		var bad: bool = false
		for dd in DIRS:
			var m: Vector2i = n + dd
			if m == cur:
				continue
			if used.has(m) or m.x == 0:
				bad = true
				break
		if bad:
			continue

		options.append(n)
	return options


func _keep_outermost(options: Array) -> Array:
	var mx: int = -999
	for o in options:
		if o.x > mx:
			mx = o.x
	var outer: Array = []
	for o in options:
		if o.x == mx:
			outer.append(o)
	return outer

# ----------------------------------------------------------------
# CONVERSAO LOCAL -> MUNDO. side ESPELHA O EIXO X.
# ----------------------------------------------------------------
func _to_world(local: Vector2i, side: int, row: int) -> Vector2i:
	return Vector2i(entry_x + side * local.x, chunk_start_z - (row + local.y))

# ----------------------------------------------------------------
# ORIENTACAO DO BAU: APONTA PARA A CELULA DE ONDE ELE E ABERTO.
# ----------------------------------------------------------------
func _facing_towards(chest_local: Vector2i, nb_local: Vector2i, side: int) -> int:
	var cx: int = side * chest_local.x
	var nx: int = side * nb_local.x
	if nx < cx:
		return CHEST_FACE_LEFT		# JOGADOR A ESQUERDA (-X)
	if nx > cx:
		return CHEST_FACE_RIGHT		# JOGADOR A DIREITA (+X)
	# local.y CRESCE PARA TRAS: z = chunk_start_z - (row + y)
	if nb_local.y > chest_local.y:
		return CHEST_FACE_BACK		# JOGADOR ATRAS (+Z)
	return CHEST_FACE_FRONT			# JOGADOR NA FRENTE (-Z)

# ================================================================
# UTIL
# ================================================================

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp