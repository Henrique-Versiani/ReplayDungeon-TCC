extends Node
class_name SectionSelector

# ================================================================
# SELETOR DE SECOES (CURVA DE TENSAO ADAPTATIVA)
# ================================================================
# A escolha da proxima categoria nao vem de tabelas fixas de peso por
# faixa, e sim de uma CURVA DE TENSAO ALVO: a cada secao existe um
# nivel de tensao desejado, e cada categoria e pontuada pelo quanto
# APROXIMA a tensao atual desse alvo.
#
# A curva alvo combina tres termos:
#   1. BASE   - cresce logaritmicamente e satura (a partida fica mais
#               dificil, mas nao indefinidamente)
#   2. ONDA   - oscilacao senoidal que cria o respiro (tensao sobe,
#               alivia, sobe de novo) em vez de uma rampa monotona
#   3. PERICIA- deslocamento adaptativo: sobe quando o jogador avanca
#               bem, desce quando ele morre. E o que torna a
#               heuristica ADAPTATIVA ao jogador real
#
# Sobre a pontuacao: usa-se uma funcao gaussiana da distancia ao alvo.
# Isso evita o determinismo de "escolher sempre a melhor": categorias
# proximas do alvo tem probabilidades parecidas, entao ha variedade
# real, mas categorias absurdas para o momento praticamente nunca saem.
#
# Regras rigidas por cima da pontuacao:
#   - nunca repete a mesma categoria em sequencia
#   - abertura suave (WARMUP_SECTIONS sem categorias tensas)
#   - alivio forcado apos FORCE_RELIEF_AFTER secoes tensas seguidas
#   - penalidade de recencia (quanto mais recente, maior a punicao)
# ================================================================

# ----- CATEGORIAS -----
const RISCO:		String = "risco"
const RUSH:			String = "rush"
const ESCOLHA:		String = "escolha"
const ATRASO:		String = "atraso"
const BIFURCACAO:	String = "bifurcacao"
const RECOMPENSA:	String = "recompensa"
const TRANSICAO:	String = "transicao"

# ----- VALOR DE TENSAO POR CATEGORIA -----
const TENSION_VALUE: Dictionary = {
	RISCO:		 3,
	RUSH:		 3,
	ESCOLHA:	 2,
	BIFURCACAO:	 1,
	ATRASO:		 0,
	TRANSICAO:	-2,
	RECOMPENSA:	-3
}

# ----- AFINIDADE BASE -----
# PREFERENCIA DE DESIGN, INDEPENDENTE DA TENSAO. VALORES MENORES FAZEM
# A CATEGORIA APARECER MENOS MESMO QUANDO ELA ENCAIXA NO ALVO.
const AFFINITY: Dictionary = {
	RISCO:		1.0,
	RUSH:		1.0,
	ESCOLHA:	0.9,
	BIFURCACAO:	0.9,
	ATRASO:		1.0,
	TRANSICAO:	0.8,
	RECOMPENSA:	0.7
}

# ----- CATEGORIAS HABILITADAS -----
# SO ENTRAM NO SORTEIO AS CATEGORIAS LISTADAS AQUI. MANTENHA FORA AS
# NAO IMPLEMENTADAS: SEM ISSO ELAS CAEM NO FALLBACK DA FACTORY E VIRAM
# TRANSICAO, O QUE FAZ A PARTIDA PARECER MUITO MAIS REPETITIVA.
@export var enabled_categories: Array[String] = [
	RISCO, RUSH, ATRASO, TRANSICAO, RECOMPENSA
]

# ----- CURVA ALVO -----
const TARGET_BASE_START:	float = 1.0		# TENSAO ALVO NO INICIO
const TARGET_BASE_GAIN:		float = 2.2		# INTENSIDADE DO CRESCIMENTO
const TARGET_BASE_RAMP:		float = 6.0		# QUANTO MAIS ALTO, MAIS LENTO O CRESCIMENTO
const TARGET_BASE_MAX:		float = 7.0		# TETO DA BASE (SATURACAO)
const TARGET_WAVE_AMP:		float = 2.2		# AMPLITUDE DO RESPIRO
const TARGET_WAVE_PERIOD:	float = 7.0		# SECOES POR CICLO DE RESPIRO
const MATCH_SIGMA:			float = 2.2		# TOLERANCIA DA GAUSSIANA (MAIOR = MAIS VARIEDADE)

# ----- ADAPTACAO AO JOGADOR -----
const SKILL_ON_DEATH:		float = -1.0	# QUEDA DE PERICIA AO MORRER
const SKILL_ON_SECTION:		float = 0.15	# GANHO POR SECAO CONCLUIDA
const SKILL_MIN:			float = -3.0
const SKILL_MAX:			float = 3.0

# ----- REGRAS RIGIDAS -----
const WARMUP_SECTIONS:		int   = 2		# SECOES INICIAIS SEM CATEGORIA TENSA
const FORCE_RELIEF_AFTER:	int   = 3		# TENSAS SEGUIDAS ANTES DO ALIVIO FORCADO
const WINDOW_SIZE:			int   = 4		# TAMANHO DA JANELA DE RECENCIA
const RECENCY_BASE:			float = 0.35	# PENALIDADE DA CATEGORIA MAIS RECENTE
const RECENCY_STEP:			float = 0.15	# ALIVIO DA PENALIDADE POR POSICAO NA JANELA

const TENSION_DECAY:		float = 0.9		# DECAIMENTO DA TENSAO ACUMULADA
const TENSION_MIN:			float = -5.0
const TENSION_MAX:			float = 10.0

# ----- ESTADO INTERNO -----
var rng:					RandomNumberGenerator = RandomNumberGenerator.new()
var _base_seed:				int		= 0

var tension_level:			float	= 0.0
var skill_estimate:			float	= 0.0
var last_category:			String	= ""
var recent_history:			Array	= []
var consecutive_tense_count: int	= 0
var sections_played:		int		= 0

# ================================================================
# API PUBLICA
# ================================================================

func choose_and_register_category() -> String:
	var category: String = _choose_category()
	_register_category(category)
	return category


func set_seed(s: int) -> void:
	"""
	DEFINE A SEMENTE. DEVE SER CHAMADA PELO GridMapManager COM A MESMA
	SEMENTE DA GERACAO, PARA QUE A SEQUENCIA SEJA REPRODUTIVEL.
	ATENCAO: NAO MEXER EM rng.state AQUI - ATRIBUIR seed JA INICIALIZA
	O ESTADO, E SOBRESCREVER state DEPOIS DESCARTA A SEMENTE.
	"""
	_base_seed = s
	rng.seed = s


func reset() -> void:
	tension_level = 0.0
	skill_estimate = 0.0
	last_category = ""
	recent_history.clear()
	consecutive_tense_count = 0
	sections_played = 0
	rng.seed = _base_seed


func register_player_death() -> void:
	"""
	CHAME QUANDO O JOGADOR MORRER. BAIXA A PERICIA ESTIMADA, O QUE
	DESLOCA A CURVA ALVO PARA BAIXO E FAZ APARECEREM MAIS SECOES DE
	ALIVIO NAS PROXIMAS ESCOLHAS.
	"""
	skill_estimate = clamp(skill_estimate + SKILL_ON_DEATH, SKILL_MIN, SKILL_MAX)


func debug_state() -> String:
	return "played=%d  tension=%.2f  target=%.2f  skill=%.2f  last=%s  consec=%d  window=%s" % [
		sections_played, tension_level, _target_tension(), skill_estimate,
		last_category, consecutive_tense_count, str(recent_history)
	]

# ================================================================
# CURVA ALVO
# ================================================================

func _target_tension() -> float:
	var n: float = float(sections_played)
	var base: float = min(
		TARGET_BASE_START + TARGET_BASE_GAIN * log(1.0 + n / TARGET_BASE_RAMP),
		TARGET_BASE_MAX
	)
	var wave: float = TARGET_WAVE_AMP * sin(TAU * n / TARGET_WAVE_PERIOD)
	return base + wave + skill_estimate

# ================================================================
# ESCOLHA
# ================================================================

func _choose_category() -> String:
	var target: float = _target_tension()
	var weights: Dictionary = {}

	for cat in enabled_categories:
		if cat == last_category:
			continue						# NUNCA REPETE EM SEQUENCIA
		var tv: int = TENSION_VALUE.get(cat, 0)
		if sections_played < WARMUP_SECTIONS and tv > 0:
			continue						# ABERTURA SUAVE
		if consecutive_tense_count >= FORCE_RELIEF_AFTER and tv > 0:
			continue						# ALIVIO FORCADO

		# AFINIDADE GAUSSIANA: QUAO PERTO DO ALVO A TENSAO FICARIA
		var predicted: float = tension_level + float(tv)
		var err: float = abs(predicted - target)
		var score: float = float(AFFINITY.get(cat, 1.0)) \
			* exp(-(err * err) / (2.0 * MATCH_SIGMA * MATCH_SIGMA))

		# PENALIDADE DE RECENCIA (MAIS RECENTE = MAIS PUNIDA)
		for k in range(recent_history.size()):
			var idx_from_end: int = recent_history.size() - 1 - k
			if recent_history[idx_from_end] == cat:
				score *= RECENCY_BASE + RECENCY_STEP * float(k)

		weights[cat] = max(score, 0.000001)

	if weights.is_empty():
		return TRANSICAO if TRANSICAO in enabled_categories else enabled_categories[0]

	return _weighted_pick(weights)


func _weighted_pick(weights: Dictionary) -> String:
	var total: float = 0.0
	for w in weights.values():
		total += float(w)
	if total <= 0.0:
		return weights.keys()[0]

	var roll: float = rng.randf() * total
	var acc: float = 0.0
	for cat in weights.keys():
		acc += float(weights[cat])
		if roll <= acc:
			return cat
	return weights.keys()[weights.size() - 1]

# ================================================================
# REGISTRO
# ================================================================

func _register_category(category: String) -> void:
	var tv: int = TENSION_VALUE.get(category, 0)

	# DECAIMENTO + CONTRIBUICAO DA CATEGORIA ESCOLHIDA
	tension_level = clamp(tension_level * TENSION_DECAY + float(tv), TENSION_MIN, TENSION_MAX)

	if tv > 0:
		consecutive_tense_count += 1
	else:
		consecutive_tense_count = 0

	recent_history.append(category)
	if recent_history.size() > WINDOW_SIZE:
		recent_history.pop_front()

	last_category = category
	sections_played += 1

	# O JOGADOR SOBREVIVEU MAIS UMA SECAO: PERICIA SOBE DEVAGAR
	if sections_played > 1:
		skill_estimate = clamp(skill_estimate + SKILL_ON_SECTION, SKILL_MIN, SKILL_MAX)