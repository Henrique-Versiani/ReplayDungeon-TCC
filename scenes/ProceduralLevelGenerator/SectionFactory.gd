extends RefCounted
class_name SectionFactory

# ----- TIPOS -----
const RISCO:		String = "risco"
const RUSH:			String = "rush"
const ESCOLHA:		String = "escolha"
const ATRASO:		String = "atraso"
const BIFURCACAO:	String = "bifurcacao"
const RECOMPENSA:	String = "recompensa"
const TRANSICAO:	String = "transicao"

func build_section(
	type_name: String,
	entry_x: int,
	chunk_start_z: int,
	base_seed: int,
	chunk_id: int,
	floor_y: int,
	floor_mesh: int
) -> Dictionary:
	var section: BaseSection = _create_section(
		type_name, entry_x, chunk_start_z, base_seed, chunk_id, floor_y, floor_mesh
	)
	return section.build()

func _create_section(
	type_name: String,
	entry_x: int,
	chunk_start_z: int,
	base_seed: int,
	chunk_id: int,
	floor_y: int,
	floor_mesh: int
) -> BaseSection:
	match type_name:
		TRANSICAO:
			return TransicaoSection.new(entry_x, chunk_start_z, base_seed, chunk_id, floor_y, floor_mesh)
		RECOMPENSA:
			return RecompensaSection.new(entry_x, chunk_start_z, base_seed, chunk_id, floor_y, floor_mesh)
		_:
			print("[SectionFactory] tipo '%s' ainda nao implementado - usando TransicaoSection" % type_name)
			return TransicaoSection.new(entry_x, chunk_start_z, base_seed, chunk_id, floor_y, floor_mesh)