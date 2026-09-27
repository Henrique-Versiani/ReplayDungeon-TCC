extends BaseSection
class_name BifurcacaoSection

# ================================================================
# BIFURCACAO
# ================================================================
# A ROTA SE DIVIDE EM 2 OU 3 RAMOS QUE SEGUEM EM FRENTE (-Z), EM FAIXAS
# PARALELAS SEPARADAS POR UMA COLUNA DE VAZIO, E SE REUNEM NUMA BARRA DE
# JUNCAO ANTES DA SAIDA.
#
# CADA RAMO TEM UM TIPO (O QUE ELE E) E UMA APARENCIA (COMO ELE PARECE):
#   TIPO SEGURO    -> SINUOSO OU TEIAS                    (LONGO, SEM PERIGO LETAL)
#   TIPO ARRISCADO -> ESPINHOS, GIRADOR, FOGO, PLATAFORMAS (CURTO, COM PERIGO E MOEDAS)
#   TIPO BECO      -> QUALQUER APARENCIA, SORTEADA COMO SE FOSSE VIAVEL,
#                     MAS TERMINA 1-2 LINHAS ANTES DA JUNCAO
#
# DIFERENCA PARA A ESCOLHA: LA O DESVIO E OPCIONAL E VOLTA PARA O MESMO
# CORREDOR; AQUI TODO RAMO SEGUE EM FRENTE E O JOGADOR PRECISA APOSTAR
# EM UM SEM SABER SE ELE CHEGA NA JUNCAO.
#
# LAYOUT EM LINHAS LOCAIS (r = PASSO, z = chunk_start_z - r):
#   0 .. fork_row-1            BUFFER DE ENTRADA (1 CELULA POR LINHA)
#   fork_row                   BARRA DO FORK (LARGURA TOTAL)
#   fork_row+1 .. merge_row-1  RAMOS, UM POR FAIXA
#   merge_row                  BARRA DE JUNCAO (LARGURA TOTAL)
#   merge_row+1 .. depth-1     BUFFER DE SAIDA (1 CELULA POR LINHA)
#
# DENTRO DESTE ARQUIVO, Vector2i(c, r) E COORDENADA LOCAL:
#   c = x - entry_x (COLUNA), r = PASSO. _wx/_wz CONVERTEM PARA O MUNDO.
# ================================================================

const BUFFER_STEPS:			int = 2		# 1 CELULA/LINHA: ISOLA AS BARRAS DAS SECOES VIZINHAS
const MAX_SPAN:				int = 7		# LARGURA TOTAL MAXIMA (COLUNAS)

# ----- COMPOSICAO -----
# A CHANCE "BRUTA" DE 3 RAMOS E ALTA PORQUE MUITAS COMPOSICOES DE 3 NAO
# CABEM EM MAX_SPAN E SAO REFEITAS. NO FIM, ~37% DAS BIFURCACOES TEM 3.
const THREE_BRANCH_CHANCE:	float = 0.60
const DEAD_END_CHANCE_TWO:	float = 0.50	# COM 3 RAMOS SEMPRE HA 1 BECO
const COMPOSE_ATTEMPTS:		int = 32
# SE true, 3 RAMOS = SEGURO + ARRISCADO + BECO. O BECO SEMPRE REPETE A
# CATEGORIA DE UM DELES, ENTAO O RAMO DE CATEGORIA UNICA E SEMPRE VIAVEL
# (O JOGADOR APRENDE "PEGA O DIFERENTE"). COM false O VAZAMENTO SOME.
const FORCE_CONTRAST_3:		bool = false

# ----- BECO -----
const DEAD_GAP_MIN:			int = 1		# LINHAS DE VAZIO ENTRE A PONTA E A JUNCAO
const DEAD_GAP_MAX:			int = 2
# SE true, O BECO TEM OS MESMOS PERIGOS DA APARENCIA QUE IMITA. CUSTA CARO
# (IDA E VOLTA PELO PERIGO), MAS SEM ISSO "TEM PERIGO" VIRA PROVA DE QUE
# O RAMO E VIAVEL.
const DEAD_MIMIC_HAZARDS:	bool = true

# ----- APARENCIAS -----
const LOOK_WINDING:	int = 0		# SERPENTINA LIMPA
const LOOK_WEBS:	int = 1		# SERPENTINA COM TEIAS NO CAMINHO (MAIS LENTA, NAO MATA)
const LOOK_SPIKES:	int = 2		# RETO COM ESPINHOS RETRATEIS
const LOOK_SPINNER:	int = 3		# RETO NA BORDA DE UMA FAIXA DE 3, GIRADOR NO CENTRO
const LOOK_FIRE:	int = 4		# IDEM, COM FOGO CIRCULAR NO CENTRO
const LOOK_FALLING:	int = 5		# RETO COM UM TRECHO DE PLATAFORMAS QUE CAEM (E AS VEZES
								# UMA CAIXA EMPURRAVEL DENTRO DELE)
# PESOS DO SORTEIO DENTRO DE CADA CATEGORIA. PARA DESLIGAR UMA APARENCIA,
# PESO 0 (OU TIRAR DA LISTA). O BECO USA OS MESMOS PESOS: E O QUE GARANTE
# QUE A APARENCIA NAO DENUNCIE QUAL RAMO E O BECO.
const SAFE_LOOK_WEIGHTS:	Array = [[LOOK_WINDING, 3], [LOOK_WEBS, 2]]
const RISKY_LOOK_WEIGHTS:	Array = [[LOOK_SPIKES, 3], [LOOK_SPINNER, 3], [LOOK_FIRE, 2], [LOOK_FALLING, 3]]

# ----- SERPENTINA -----
const WIND_RUN_CHANCE:		float = 0.75
const WIND_ATTEMPTS:		int = 12
const SAFE_MIN_EXTRA:		int = 2		# PASSOS A MAIS QUE O RAMO RETO, NO MINIMO
const WEBS_MIN:				int = 1
const WEBS_MAX:				int = 2
const WEB_SPACING:			int = 2

# ----- ESPINHOS -----
const RISKY_SPIKES_MIN:		int = 1
const RISKY_SPIKES_MAX:		int = 3
const SPIKE_SPACING:		int = 2		# SEMPRE SOBRA 1 CELULA DE ESPERA ENTRE ESPINHOS
const EDGE_MARGIN:			int = 1		# NADA NA 1a CELULA (ENCOSTA NO FORK) NEM NA ULTIMA
										# (NO BECO, O CORTE DA CAUDA PODE DEIXAR UM NA PONTA)
const RISKY_COIN_DENSITY:	float = 0.5

# ----- GIRADOR / FOGO ("DISCO") -----
# A BARRA DO GIRADOR TEM 5 BLOCOS (2 PARA CADA LADO DO PIVO) E O FOGO
# CIRCULAR ORBITA COM RAIO 2: OS DOIS VARREM UM QUADRADO 5x5 EM TORNO DO
# PIVO. POR ISSO A FAIXA DELES TEM EXATAMENTE 3 COLUNAS COM O PIVO NO
# CENTRO: FAIXA (3) + OS DOIS SEPARADORES VAZIOS (1 + 1) = 5, E A BARRA
# TERMINA NA FRONTEIRA COM A FAIXA VIZINHA, SEM NUNCA ALCANCA-LA.
# O CAMINHO PASSA NUMA BORDA DA FAIXA, AO LADO DO PIVO.
const DISK_REACH:			int = 2
# NO MAXIMO 1 FAIXA DE DISCO POR SECAO. DUAS FAIXAS DE DISCO VIZINHAS
# DIVIDEM O SEPARADOR E AS BARRAS SE CRUZARIAM NELE; NAO HA PROFUNDIDADE
# PARA DESENCONTRAR OS PIVOS (PRECISARIAM DE 5 LINHAS DE DIFERENCA).
const MAX_DISK_LANES:		int = 1

# ----- PLATAFORMAS QUE CAEM -----
# NUM RAMO VIAVEL O CORREDOR PODE IR ATE A JUNCAO: A PLATAFORMA SO PRECISA
# AGUENTAR UMA PASSADA. NUM BECO O JOGADOR TEM QUE VOLTAR POR CIMA DELAS,
# ENTAO A PONTA DO BECO FICA DEAD_FALL_REACH CELULAS DEPOIS DA PRIMEIRA
# PLATAFORMA: A IDA E A VOLTA CUSTAM (2*REACH + 1) PASSOS, QUE PRECISAM
# CABER NO TEMPO QUE A PLATAFORMA LEVA PARA SUMIR.
# PARA QUE ISSO NAO DENUNCIE O BECO, O TRECHO NUNCA COMECA ANTES DE
# FALL_MIN_START: ASSIM A PONTA DE UM BECO DE PLATAFORMAS CAI NA MESMA
# DISTANCIA MINIMA DO FORK QUE A PONTA DE QUALQUER OUTRO BECO, E ATE LA
# OS DOIS SAO IGUAIS.
const DEAD_FALL_REACH:		int = 2
const MIN_TIP_INDEX:		int = 5		# PONTA DE BECO MAIS PROXIMA POSSIVEL
										# (RAMO DE 8 LINHAS COM VAO DE 2)
const FALL_MIN_START:		int = MIN_TIP_INDEX - DEAD_FALL_REACH
const FALL_LONG:			bool = true	# VIAVEL VAI ATE A JUNCAO (false = SO O TRECHO CURTO)
# CAIXA EMPURRAVEL DENTRO DO CORREDOR. O JOGADOR EMPURRA ATE O FIM E A
# DERRUBA NO VAZIO: NO BECO, PARA ALEM DA PONTA; NO VIAVEL, PARA ALEM DA
# BARRA DE JUNCAO (POR ISSO A COLUNA DA SAIDA NUNCA E A DO CORREDOR).
const GOLEM_CHANCE:			float = 0.45

# ----- TIPOS -----
const TYPE_SAFE:	int = 0
const TYPE_RISKY:	int = 1
const TYPE_DEAD:	int = 2

var fork_row:	int
var merge_row:	int
var span_lo:	int
var span_hi:	int
var branches:	Array = []

# ================================================================
# OVERRIDES
# ================================================================

func _depth_min() -> int:	return 14	# RAMOS DE 8 A 12 LINHAS
func _depth_max() -> int:	return 18
func _width_min() -> int:	return 1	# NAO USADO (LARGURA VEM DAS FAIXAS)
func _width_max() -> int:	return 1
func type_name() -> String:	return "bifurcacao"

# ================================================================
# BUILD
# ================================================================

func build() -> Dictionary:
	fork_row = BUFFER_STEPS
	merge_row = depth - BUFFER_STEPS - 1

	_compose_and_layout()
	_generate_branches()

	var exit_c: int = _pick_exit_column()
	exit_x = entry_x + exit_c

	_carve_all(exit_c)
	_mark_reference_route(exit_c)
	_place_content()

	finalize()
	return get_result()

# ================================================================
# COMPOSICAO E FAIXAS
# ================================================================

func _compose_and_layout() -> void:
	# REFAZ A COMPOSICAO QUANDO ELA NAO CABE (LARGURA OU DISCOS DEMAIS).
	# A REJEICAO DEPENDE SO DAS APARENCIAS, E AS APARENCIAS SAO SORTEADAS
	# SEM OLHAR QUAL RAMO E BECO: LOGO NAO CRIA CORRELACAO COM VIABILIDADE.
	var fits: bool = false
	for _attempt in range(COMPOSE_ATTEMPTS):
		branches = _compose()
		if _fits():
			fits = true
			break
	if not fits:
		# CONTINGENCIA (PROBABILIDADE ~1e-8): COMPOSICAO QUE SEMPRE CABE
		branches = [_new_branch(TYPE_SAFE, LOOK_WINDING), _new_branch(TYPE_RISKY, LOOK_SPIKES)]
		_shuffle(branches)

	# SERPENTINAS COMECAM COM 3 COLUNAS E ENCOLHEM PARA 2 ATE CABER.
	# FAIXA DE DISCO NUNCA ENCOLHE (A BARRA ALCANCARIA A FAIXA VIZINHA).
	for b in branches:
		b["lane_w"] = _lane_width(b["look"], 3)
	while _span_from_lanes() > MAX_SPAN:
		var wide: Array = []
		for b in branches:
			if _is_winding(b["look"]) and b["lane_w"] == 3:
				wide.append(b)
		if wide.is_empty():
			push_warning("[bifurcacao] composicao nao cabe em MAX_SPAN=%d" % MAX_SPAN)
			break
		wide[rng.randi() % wide.size()]["lane_w"] = 2

	# FAIXAS DA ESQUERDA PARA A DIREITA, CENTRADAS NA ENTRADA, COM UMA
	# COLUNA DE VAZIO ENTRE ELAS (E O QUE IMPEDE ATALHO ENTRE RAMOS)
	var span: int = _span_from_lanes()
	span_lo = -((span - 1) / 2)
	span_hi = span_lo + span - 1
	var col: int = span_lo
	for b in branches:
		b["lo"] = col
		b["hi"] = col + b["lane_w"] - 1
		col = b["hi"] + 2


func _compose() -> Array:
	var n: int = 3 if rng.randf() < THREE_BRANCH_CHANCE else 2
	var types: Array = []
	if n == 3 and FORCE_CONTRAST_3:
		types = [TYPE_SAFE, TYPE_RISKY, TYPE_DEAD]
	elif n == 3:
		types = [_rand_viable(), _rand_viable(), TYPE_DEAD]
	elif rng.randf() < DEAD_END_CHANCE_TWO:
		types = [_rand_viable(), TYPE_DEAD]
	else:
		# 2 RAMOS SEM BECO: GARANTE O CONTRASTE DE DIFICULDADE
		types = [TYPE_SAFE, TYPE_RISKY]
	# EMBARALHA: A POSICAO DA FAIXA NAO PODE DENUNCIAR O BECO
	_shuffle(types)

	var result: Array = []
	for t in types:
		# O BECO SORTEIA UMA CATEGORIA E DEPOIS A APARENCIA COM OS MESMOS
		# PESOS DOS VIAVEIS: A DISTRIBUICAO FICA IDENTICA A DE UM VIAVEL
		var cat: int = _rand_viable() if t == TYPE_DEAD else t
		var look: int = _weighted_look(SAFE_LOOK_WEIGHTS if cat == TYPE_SAFE else RISKY_LOOK_WEIGHTS)
		result.append(_new_branch(t, look))
	return result


func _new_branch(t: int, look: int) -> Dictionary:
	return {
		"type":		t,
		"look":		look,
		"lane_w":	1,
		"lo":		0,
		"hi":		0,
		"tip_row":	0,
		"cells":	[],
		"spikes":	[],
		"coins":	[],
		"webs":		[],
		"disks":	[],	# PIVOS EM COORDENADA LOCAL
		"fall_start":	-1,	# INDICE DA 1a PLATAFORMA QUE CAI (-1 = NENHUMA)
		"fall_end":		-1,
		"golem":		-1	# INDICE DA CAIXA (-1 = NENHUMA)
	}


func _fits() -> bool:
	var span: int = branches.size() - 1
	var disk_lanes: int = 0
	for b in branches:
		span += _lane_width(b["look"], 2)
		if _is_disk(b["look"]):
			disk_lanes += 1
	return span <= MAX_SPAN and disk_lanes <= MAX_DISK_LANES


func _span_from_lanes() -> int:
	var total: int = branches.size() - 1
	for b in branches:
		total += b["lane_w"]
	return total


func _lane_width(look: int, winding_w: int) -> int:
	if _is_winding(look):
		return winding_w
	if _is_disk(look):
		return 3
	return 1


func _rand_viable() -> int:
	return TYPE_SAFE if rng.randf() < 0.5 else TYPE_RISKY


func _weighted_look(pairs: Array) -> int:
	var total: int = 0
	for p in pairs:
		total += p[1]
	var roll: int = rng.randi_range(0, total - 1)
	for p in pairs:
		if roll < p[1]:
			return p[0]
		roll -= p[1]
	return pairs[pairs.size() - 1][0]


func _is_winding(look: int) -> bool:
	return look == LOOK_WINDING or look == LOOK_WEBS


func _is_disk(look: int) -> bool:
	return look == LOOK_SPINNER or look == LOOK_FIRE

# ================================================================
# RAMOS
# ================================================================
# TODO RAMO E GERADO COMO SE FOSSE VIAVEL (ATE A LINHA ANTES DA JUNCAO),
# O CONTEUDO E SORTEADO NO RAMO INTEIRO, E SO DEPOIS O BECO PERDE A
# CAUDA. ASSIM, ATE A PONTA, UM BECO E ESTATISTICAMENTE IDENTICO A UM
# RAMO VIAVEL DA MESMA APARENCIA. SE O CONTEUDO FOSSE SORTEADO DEPOIS
# DO CORTE, O BECO TERIA MENOS PERIGO/MOEDA EM MEDIA E ISSO VAZARIA.
# ----------------------------------------------------------------

func _generate_branches() -> void:
	var first_row: int = fork_row + 1
	var last_row: int = merge_row - 1

	for b in branches:
		_gen_branch(b, first_row, last_row)

		b["tip_row"] = last_row
		if b["type"] == TYPE_DEAD:
			if b["look"] == LOOK_FALLING:
				# A PONTA VEM LOGO DEPOIS DA 1a PLATAFORMA: E O QUE DA TEMPO DE VOLTAR
				b["tip_row"] = b["cells"][b["fall_start"]].y + DEAD_FALL_REACH
			else:
				b["tip_row"] = last_row - rng.randi_range(DEAD_GAP_MIN, DEAD_GAP_MAX)
			var tip: int = b["tip_row"]
			# AS LINHAS DO RAMO NUNCA DIMINUEM, ENTAO O CORTE E UM PREFIXO
			# (E PREFIXO DE CAMINHO INDUZIDO CONTINUA INDUZIDO)
			var keep: int = 0
			for cell in b["cells"]:
				if cell.y <= tip:
					keep += 1
			b["cells"] = b["cells"].slice(0, keep)
			b["spikes"] = b["spikes"].filter(func(i): return i < keep)
			b["coins"] = b["coins"].filter(func(i): return i < keep)
			b["webs"] = b["webs"].filter(func(i): return i < keep)
			b["disks"] = b["disks"].filter(func(p): return p.y <= tip)
			if b["golem"] >= keep:
				b["golem"] = -1
			b["fall_end"] = mini(b["fall_end"], keep - 1)
			if not DEAD_MIMIC_HAZARDS:
				b["spikes"] = []
				b["disks"] = []


func _gen_branch(b: Dictionary, first_row: int, last_row: int) -> void:
	var look: int = b["look"]
	var cells: Array = []

	match look:
		LOOK_WINDING, LOOK_WEBS:
			cells = _gen_winding(b["lo"], b["hi"], first_row, last_row)
			if look == LOOK_WEBS:
				# TEIA NAO MATA, SO ATRASA: DEIXA A ROTA SEGURA AINDA MAIS CARA
				b["webs"] = _pick_spaced(cells.size(), WEBS_MIN, WEBS_MAX, WEB_SPACING)

		LOOK_SPIKES:
			for r in range(first_row, last_row + 1):
				cells.append(Vector2i(b["lo"], r))
			b["spikes"] = _pick_spaced(cells.size(), RISKY_SPIKES_MIN, RISKY_SPIKES_MAX, SPIKE_SPACING)

		LOOK_FALLING:
			for r in range(first_row, last_row + 1):
				cells.append(Vector2i(b["lo"], r))
			b["fall_start"] = rng.randi_range(FALL_MIN_START, cells.size() - 2 - DEAD_FALL_REACH)
			b["fall_end"] = (cells.size() - 1) if FALL_LONG else (b["fall_start"] + DEAD_FALL_REACH)
			if rng.randf() < GOLEM_CHANCE:
				# CAIXA SEMPRE A FRENTE DO JOGADOR, JA DENTRO DO CORREDOR
				b["golem"] = b["fall_start"] + 1

		_:
			# GIRADOR / FOGO: CAMINHO RETO NUMA DAS BORDAS, PIVO NO CENTRO.
			# LINHA DO PIVO:
			#   >= first_row + DISK_REACH  -> A BARRA NUNCA ALCANCA A BARRA DO
			#      FORK, E A CELULA DO FORK FICA COMO LUGAR SEGURO DE ESPERA
			#   <= last_row - DEAD_GAP_MAX - DISK_REACH - 1  -> MESMO NO BECO
			#      MAIS CURTO SOBRA UMA CELULA SEGURA DEPOIS DA FAIXA VARRIDA,
			#      ENTAO A PONTA DO BECO NUNCA FICA DENTRO DO ALCANCE (DARIA
			#      PARA ENTRAR MAS NAO DARIA TEMPO DE VOLTAR). COMO VALE PARA
			#      TODO RAMO, VIAVEL OU BECO, A POSICAO DO PIVO NAO VAZA NADA.
			var edge: int = b["lo"] if rng.randf() < 0.5 else b["hi"]
			for r in range(first_row, last_row + 1):
				cells.append(Vector2i(edge, r))
			var lo_r: int = first_row + DISK_REACH
			var hi_r: int = last_row - DEAD_GAP_MAX - DISK_REACH - 1
			b["disks"] = [Vector2i(b["lo"] + 1, rng.randi_range(lo_r, hi_r))]

	if not _is_winding(look):
		# MOEDAS SO NAS APARENCIAS ARRISCADAS: O RISCO PRECISA PAGAR ALGO,
		# SENAO A ROTA LONGA DOMINA SEMPRE
		for i in range(cells.size()):
			if i in b["spikes"] or i == b["golem"]:
				continue
			if rng.randf() < RISKY_COIN_DENSITY:
				b["coins"].append(i)

	b["cells"] = cells

# ----------------------------------------------------------------
# SERPENTINA INDUZIDA (1 BLOCO DE LARGURA) DENTRO DA FAIXA [lo, hi].
# EM CADA LINHA O RAMO PODE FAZER UMA "CORRIDA" HORIZONTAL. REGRAS QUE
# GARANTEM QUE NAO APARECA BLOCO 2x2 NEM ATALHO:
#   - NUNCA CORRE NA 1a LINHA (ENCOSTARIA NA BARRA DO FORK) NEM NA
#     ULTIMA (ENCOSTARIA NA JUNCAO)
#   - ENTRE DUAS CORRIDAS HA PELO MENOS 1 LINHA RETA
# COMO AS LINHAS SO CRESCEM E DUAS CORRIDAS NUNCA FICAM EM LINHAS
# VIZINHAS, CADA CELULA SO TOCA A ANTERIOR E A SEGUINTE (INDUZIDO).
# REPETE ATE O RAMO TER SAFE_MIN_EXTRA PASSOS A MAIS QUE O RETO.
# ----------------------------------------------------------------
func _gen_winding(lo: int, hi: int, r0: int, r1: int) -> Array:
	var straight_len: int = r1 - r0 + 1
	var best: Array = []
	var best_extra: int = -1
	for _attempt in range(WIND_ATTEMPTS):
		var cells: Array = _try_winding(lo, hi, r0, r1)
		var extra: int = cells.size() - straight_len
		if extra > best_extra:
			best_extra = extra
			best = cells
		if extra >= SAFE_MIN_EXTRA:
			return cells
	return best


func _try_winding(lo: int, hi: int, r0: int, r1: int) -> Array:
	var cur: int = rng.randi_range(lo, hi)
	var cells: Array = []
	var last_run: int = -99

	for r in range(r0, r1 + 1):
		cells.append(Vector2i(cur, r))
		var can_run: bool = r != r0 and r != r1 and r - last_run >= 2 and hi > lo
		if can_run and rng.randf() < WIND_RUN_CHANCE:
			var opts: Array = []
			for c in range(lo, hi + 1):
				if c != cur:
					opts.append(c)
			var target: int = opts[rng.randi() % opts.size()]
			var step: int = 1 if target > cur else -1
			var walk: int = cur + step
			while true:
				cells.append(Vector2i(walk, r))
				if walk == target:
					break
				walk += step
			cur = target
			last_run = r
	return cells

# ----------------------------------------------------------------
# INDICES (AO LONGO DO RAMO) ESPACADOS, FORA DAS PONTAS
# ----------------------------------------------------------------
func _pick_spaced(n: int, kmin: int, kmax: int, spacing: int) -> Array:
	var idx: Array = []
	for i in range(EDGE_MARGIN, n - EDGE_MARGIN):
		idx.append(i)
	_shuffle(idx)

	var target: int = rng.randi_range(kmin, kmax)
	var used: Array = []
	for i in idx:
		if used.size() >= target:
			break
		var too_close: bool = false
		for j in used:
			if absi(i - j) < spacing:
				too_close = true
				break
		if too_close:
			continue
		used.append(i)
	used.sort()
	return used

# ================================================================
# ESCULPIR, MAIN_PATH E CONTEUDO
# ================================================================

# A CAIXA E DERRUBADA NO FIM DO CORREDOR, ENTAO A CELULA DEPOIS DA BARRA DE
# JUNCAO PRECISA SER VAZIO NAQUELA COLUNA. A REGRA VALE PARA RAMO VIAVEL E
# PARA BECO: SE VALESSE SO PARA UM, A COLUNA DA SAIDA DENUNCIARIA QUAL E QUAL.
func _pick_exit_column() -> int:
	var forbidden: Dictionary = {}
	for b in branches:
		if b["golem"] >= 0:
			forbidden[b["cells"][b["cells"].size() - 1].x] = true

	var options: Array = []
	for c in [-1, 0, 1]:
		var cc: int = clampi(c, span_lo, span_hi)
		if not forbidden.has(cc) and not options.has(cc):
			options.append(cc)
	if options.is_empty():
		for c in range(span_lo, span_hi + 1):
			if not forbidden.has(c):
				options.append(c)
	return options[rng.randi() % options.size()]


func _carve_all(exit_c: int) -> void:
	for r in range(0, fork_row):
		carve_floor(_wx(0), _wz(r))
	for c in range(span_lo, span_hi + 1):
		carve_floor(_wx(c), _wz(fork_row))
		carve_floor(_wx(c), _wz(merge_row))
	for r in range(merge_row + 1, depth):
		carve_floor(_wx(exit_c), _wz(r))
	for b in branches:
		for cell in b["cells"]:
			carve_floor(_wx(cell.x), _wz(cell.y))
		# O PIVO PRECISA DE CHAO (add_hazard EXIGE). ELE VIRA UM "BOLSO"
		# ENCOSTADO SO NO CAMINHO DO PROPRIO RAMO: O BFS DA BASE CONTA ESSA
		# CELULA COMO CHAO, MAS COMO ELA NAO LIGA NADA A NADA, E INOFENSIVO
		for p in b["disks"]:
			carve_floor(_wx(p.x), _wz(p.y))
		if b["fall_start"] >= 0:
			for i in range(b["fall_start"], b["fall_end"] + 1):
				var fc: Vector2i = b["cells"][i]
				replace_floor(_wx(fc.x), _wz(fc.y), PLATFORM_FALLING)

# ----------------------------------------------------------------
# MAIN_PATH = UMA ROTA DE REFERENCIA VIAVEL (O PRIMEIRO SEGURO; SE NAO
# HOUVER, O PRIMEIRO ARRISCADO). SO ELA E MARCADA, PARA O main_path
# CONTINUAR SENDO "A ROTA SEGURA". CADA LINHA CONSECUTIVA DELA TEM UM
# PASSO VERTICAL ALINHADO, ENTAO O ensure_4dir_connectivity DO finalize
# NAO ESCULPE NADA NOVO (SE ESCULPISSE, PODERIA LIGAR FAIXAS).
# O PIVO NUNCA ESTA NO CAMINHO, ENTAO NUNCA E main_path.
# ----------------------------------------------------------------
func _mark_reference_route(exit_c: int) -> void:
	var ref: Dictionary = {}
	for b in branches:
		if b["type"] == TYPE_SAFE:
			ref = b
			break
	if ref.is_empty():
		for b in branches:
			if b["type"] == TYPE_RISKY:
				ref = b
				break

	for r in range(0, fork_row):
		mark_main(_wx(0), _wz(r))

	var start_c: int = ref["cells"][0].x
	for c in range(mini(0, start_c), maxi(0, start_c) + 1):
		mark_main(_wx(c), _wz(fork_row))

	for cell in ref["cells"]:
		mark_main(_wx(cell.x), _wz(cell.y))

	var end_c: int = ref["cells"][ref["cells"].size() - 1].x
	for c in range(mini(end_c, exit_c), maxi(end_c, exit_c) + 1):
		mark_main(_wx(c), _wz(merge_row))

	for r in range(merge_row + 1, depth):
		mark_main(_wx(exit_c), _wz(r))


func _place_content() -> void:
	for b in branches:
		if b["golem"] >= 0:
			var gc: Vector2i = b["cells"][b["golem"]]
			add_pushable(_wx(gc.x), _wz(gc.y))
		for p in b["disks"]:
			# PERIGO PERMANENTE FORA DO CAMINHO: add_hazard (RECUSA main_path)
			add_hazard(_wx(p.x), _wz(p.y), _disk_mesh(b["look"]), ORIENT_DOWN)
		for i in b["spikes"]:
			var cell: Vector2i = b["cells"][i]
			# ESPINHO RETRATIL E PERIGO CRONOMETRADO: _try_add_object, QUE
			# ACEITA O MAIN_PATH (A ROTA DE REFERENCIA PODE SER A ARRISCADA)
			_try_add_object(_wx(cell.x), _wz(cell.y), SPIKE, ORIENT_DOWN)
		for i in b["webs"]:
			var cell: Vector2i = b["cells"][i]
			add_decoration(_wx(cell.x), _wz(cell.y), WEB)
		for i in b["coins"]:
			var cell: Vector2i = b["cells"][i]
			add_decoration(_wx(cell.x), _wz(cell.y), COIN)


func _disk_mesh(look: int) -> int:
	return SPINNER_DOUBLE if look == LOOK_SPINNER else FIRE_CIRCLE

# ================================================================
# RESULTADO
# ================================================================
# ALEM DO PADRAO, EXPOE OS RAMOS EM COORDENADAS DE MUNDO. O GridMapManager
# IGNORA ESSA CHAVE; ELA SERVE PARA LOGAR QUAL RAMO O JOGADOR (OU O AGENTE
# DE RL) ESCOLHEU E SE ENTROU NUM BECO - DADO PARA O CAPITULO DE RESULTADOS.
# ----------------------------------------------------------------
func get_result() -> Dictionary:
	var result: Dictionary = super.get_result()
	var meta: Array = []
	for b in branches:
		var world_cells: Array = []
		for cell in b["cells"]:
			world_cells.append(Vector3i(_wx(cell.x), floor_y, _wz(cell.y)))
		var world_disks: Array = []
		for p in b["disks"]:
			world_disks.append(Vector3i(_wx(p.x), floor_y, _wz(p.y)))
		var world_golem: Array = []
		if b["golem"] >= 0:
			var gc: Vector2i = b["cells"][b["golem"]]
			world_golem.append(Vector3i(_wx(gc.x), floor_y, _wz(gc.y)))
		meta.append({
			"type":		_type_label(b["type"]),
			"look":		_look_label(b["look"]),
			"cells":	world_cells,
			"disks":	world_disks,
			"golem":	world_golem,
			"fall":		[b["fall_start"], b["fall_end"]]
		})
	result["branches"] = meta
	return result


func _type_label(t: int) -> String:
	match t:
		TYPE_SAFE:	return "seguro"
		TYPE_RISKY:	return "arriscado"
	return "beco"


func _look_label(look: int) -> String:
	match look:
		LOOK_WINDING:	return "sinuoso"
		LOOK_WEBS:		return "teias"
		LOOK_SPIKES:	return "espinhos"
		LOOK_SPINNER:	return "girador"
		LOOK_FALLING:	return "plataformas"
	return "fogo"

# ================================================================
# UTIL
# ================================================================

func _wx(c: int) -> int:
	return entry_x + c

func _wz(r: int) -> int:
	return chunk_start_z - r

func _shuffle(arr: Array) -> void:
	for i in range(arr.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp = arr[i]
		arr[i] = arr[j]
		arr[j] = tmp