extends Node
class_name SectionSelector

# ----- CATEGORIAS -----
const RISCO:		String = "risco"
const RUSH:			String = "rush"
const ESCOLHA:		String = "escolha"
const ATRASO:		String = "atraso"
const BIFURCACAO:	String = "bifurcacao"
const RECOMPENSA:	String = "recompensa"
const TRANSICAO:	String = "transicao"

# ----- CLASSIFICACAO -----
const TENSE_CATEGORIES:  Array = [RISCO, RUSH, ESCOLHA]
const RELIEF_CATEGORIES: Array = [RECOMPENSA, TRANSICAO, ATRASO]

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

# ----- FAIXAS DE TENSAO -----
const HIGH_THRESHOLD:	int = 5
const LOW_THRESHOLD:	int = 1

# ----- PESOS BASE POR FAIXA DE TENSAO -----
const WEIGHTS_HIGH_TENSION: Dictionary = {
	RECOMPENSA:	10,
	TRANSICAO:	 8,
	ATRASO:		 6,
	BIFURCACAO:	 3,
	ESCOLHA:	 1,
	RISCO:		 1,
	RUSH:		 1
}
const WEIGHTS_MID_TENSION: Dictionary = {
	RISCO:		 5,
	RUSH:		 5,
	ESCOLHA:	 5,
	BIFURCACAO:	 4,
	ATRASO:		 4,
	TRANSICAO:	 3,
	RECOMPENSA:	 2
}
const WEIGHTS_LOW_TENSION: Dictionary = {
	RISCO:		10,
	RUSH:		 8,
	ESCOLHA:	 6,
	BIFURCACAO:	 4,
	ATRASO:		 3,
	TRANSICAO:	 2,
	RECOMPENSA:	 1
}

# ----- PENALIDADES -----
const REPEAT_PENALTY:	float = 0.05
const WINDOW_PENALTY:	float = 0.4
const WINDOW_SIZE:		int   = 4
const FORCE_RELIEF_AFTER: int = 3

const WARMUP_SECTIONS:		int   = 3
const RAMP_RATE:			float = 5.0
const MAX_PROGRESSION_FACTOR: float = 3.0
const TENSE_GAIN:			float = 0.8
const RELIEF_DECAY:			float = 0.25

# ----- ESTADO INTERNO -----
var tension_level:				int		= 0
var last_category:				String	= ""
var recent_history:				Array	= []
var consecutive_tense_count:	int		= 0
var sections_played:			int		= 0

func choose_and_register_category() -> String:
	"""
	ESCOLHE A PROXIMA CATEGORIA E JA REGISTRA NO ESTADO INTERNO.
	USADO PELO PIPELINE DE GERACAO PROCEDURAL (SectionBuilder).
	"""
	var category: String = _choose_category()
	_register_category(category)
	return category


func reset() -> void:
	"""
	RESETA O ESTADO. CHAME AO INICIAR/RESETAR O MAPA.
	"""
	tension_level = 0
	last_category = ""
	recent_history.clear()
	consecutive_tense_count = 0
	sections_played = 0


func debug_state() -> String:
	"""
	RETORNA UMA STRING COM O ESTADO ATUAL DO SELETOR (PARA LOGS).
	"""
	return "played=%d  tension=%d  last=%s  consec_tense=%d  window=%s  prog=%.2f  tMult=%.2f  rMult=%.2f" % [
		sections_played, tension_level, last_category, consecutive_tense_count,
		str(recent_history), _progression_factor(),
		_tense_multiplier(), _relief_multiplier()
	]

func _choose_category() -> String:
	"""
	APLICA A LOGICA DE CURVA DE TENSAO + DIFICULDADE + PENALIDADES.
	"""
	if consecutive_tense_count >= FORCE_RELIEF_AFTER:
		return _weighted_pick(_relief_only_weights())

	var base_weights: Dictionary
	if tension_level >= HIGH_THRESHOLD:
		base_weights = WEIGHTS_HIGH_TENSION.duplicate()
	elif tension_level <= LOW_THRESHOLD:
		base_weights = WEIGHTS_LOW_TENSION.duplicate()
	else:
		base_weights = WEIGHTS_MID_TENSION.duplicate()

	var tense_mult:  float = _tense_multiplier()
	var relief_mult: float = _relief_multiplier()
	for cat in base_weights.keys():
		if cat in TENSE_CATEGORIES:
			base_weights[cat] = float(base_weights[cat]) * tense_mult
		elif cat in RELIEF_CATEGORIES:
			base_weights[cat] = float(base_weights[cat]) * relief_mult

	if last_category != "" and base_weights.has(last_category):
		base_weights[last_category] = base_weights[last_category] * REPEAT_PENALTY

	for cat in recent_history:
		if base_weights.has(cat):
			base_weights[cat] = base_weights[cat] * WINDOW_PENALTY

	return _weighted_pick(base_weights)


func _weighted_pick(weights: Dictionary) -> String:
	"""
	SORTEIO PONDERADO ENTRE AS CATEGORIAS.
	"""
	var total: float = 0.0
	for w in weights.values():
		total += float(w)

	if total <= 0.0:
		return TRANSICAO

	var roll: float = randf() * total
	var acc: float = 0.0
	for cat in weights.keys():
		acc += float(weights[cat])
		if roll <= acc:
			return cat
	return weights.keys()[weights.size() - 1]


func _relief_only_weights() -> Dictionary:
	"""
	TABELA USADA QUANDO O CONSECUTIVE_TENSE TRIGGERA UM ALIVIO FORCADO.
	"""
	return {
		RECOMPENSA: 5,
		TRANSICAO:  4,
		ATRASO:		2
	}

func _progression_factor() -> float:
	"""
	FATOR LOGARITMICO SATURADO DA DIFICULDADE (0 -> ~3)
	"""
	if sections_played <= WARMUP_SECTIONS:
		return 0.0
	var effective: int = sections_played - WARMUP_SECTIONS
	var factor: float = log(1.0 + float(effective) / RAMP_RATE)
	return min(factor, MAX_PROGRESSION_FACTOR)


func _tense_multiplier() -> float:
	return 1.0 + _progression_factor() * TENSE_GAIN


func _relief_multiplier() -> float:
	var m: float = 1.0 - _progression_factor() * RELIEF_DECAY
	return max(m, 0.15)

func _register_category(category: String) -> void:
	"""
	ATUALIZA O ESTADO INTERNO APOS UMA ESCOLHA.
	"""
	tension_level += TENSION_VALUE.get(category, 0)
	tension_level = clamp(tension_level, -5, 10)

	if TENSION_VALUE.get(category, 0) > 0:
		consecutive_tense_count += 1
	else:
		consecutive_tense_count = 0

	recent_history.append(category)
	if recent_history.size() > WINDOW_SIZE:
		recent_history.pop_front()

	last_category = category
	sections_played += 1