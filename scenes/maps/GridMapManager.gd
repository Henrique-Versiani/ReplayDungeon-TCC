extends GridMap
@onready var gridmap = $"."
@onready var player  = $"../Player"

@onready var maps_scene 				= preload("res://scenes/maps/Maps.tscn")
@onready var coin_scene 				= preload("res://scenes/objects/Coin.tscn")
@onready var plataform_falling_scene 	= preload("res://scenes/platforms/PlatformFalling.tscn")
@onready var spike_scene 				= preload("res://scenes/traps/spike/Spike.tscn")
@onready var web_scene 					= preload("res://scenes/traps/web/Web.tscn")
@onready var saw_scene 					= preload("res://scenes/traps/saw/Saw.tscn")
@onready var spinner_double_scene 		= preload("res://scenes/traps/spinner/SpinnerDouble.tscn")
@onready var arrow_shooter_scene 		= preload("res://scenes/traps/shooter/shooter.tscn")
@onready var chest_scene 				= preload("res://scenes/objects/chest/chest.tscn")
@onready var slime_shooter_scene 		= preload("res://scenes/traps/Slime/SlimeShooter.tscn")
@onready var teleporter_scene 			= preload("res://scenes/objects/teleporter/teleporter.tscn")
@onready var pusher_scene 				= preload("res://scenes/traps/pusher/Pusher.tscn")
@onready var bat_circle_scene 			= preload("res://scenes/enemys/bat/BatCircle.tscn")
@onready var bat_on_spot_scene 			= preload("res://scenes/enemys/bat/BatOnSpot.tscn")
@onready var skeleton_scene 			= preload("res://scenes/enemys/skeleton/skeleton.tscn")
@onready var esquentadinho_h_scene 		= preload("res://scenes/enemys/esquentadinho/EsquentadinhoHorizontal.tscn")
@onready var esquentadinho_c_scene 		= preload("res://scenes/enemys/esquentadinho/EsquentadinhoCircle.tscn")
@onready var golem_scene 				= preload("res://scenes/enemys/golem/golem.tscn")
@onready var fire_shooter_scene 		= preload("res://scenes/traps/shooter/FireShooter.tscn")
@onready var one_fire_shooter_scene 	= preload("res://scenes/traps/shooter/OneFireShooter.tscn")
@onready var one_slime_shooter_scene 	= preload("res://scenes/traps/Slime/OneSlimeShooter.tscn")
@onready var section_factory_script 	= preload("res://scenes/ProceduralLevelGenerator/SectionFactory.gd")

@onready var section_selector: SectionSelector = SectionSelector.new()

const PLATFORM_FALLING_MESH:int = 0
const COIN_MESH:int				= 2
const WEB_MESH:int 				= 3
const CHEST_MESH:int 			= 4
const SAW_MESH:int 				= 6
const SPINNER_DOUBLE_MESH:int 	= 7
const ARROW_SHOOTER_MESH:int 	= 8
const SLIME_SHOOTER_MESH:int 	= 9	
const SPIKE_MESH:int 			= 10
const TELEPORTER_MESH:int 		= 11
const PUSHER_MESH:int 			= 12
const BAT_ON_SPOT_MESH:int 		= 13
const BAT_CIRCLE_MESH:int 		= 14
const SKELETON_MESH:int 		= 15
const FIRE_HORIZONTAL_MESH:int	= 16
const FIRE_CIRCLE_MESH:int		= 17
const DIAMOND_MESH:int			= 18
const STAR_MESH:int				= 19
const GOLEM_MESH:int			= 20
const FIRE_SHOOTER_MESH:int 	= 21
const ONE_FIRE_SHOOTER_MESH:int = 22
const ONE_SLIME_SHOOTER_MESH:int = 23

"""TEMPORARIO PENSAR NUMA SOLUCAO MELHOR PARA CONEXAO DE TELEPORTERS"""
var distances:Array = []

var teleport_final:Array 		= []
var maps_names:Array 			= []
var maps_data_list:Array 		= []
var objects_instances:Array 	= []
var count: 			int = 0
var next_chunk_id: int = 0
var global_max_z: 	int = 0
var level:          int = 0

# ----- VARIAVEIS DO PIPELINE PROCEDURAL -----
var section_factory
var procedural_last_exit_x: int = 22

@export var procedural_seed: int = 51257
@export var procedural_floor_y: int = 0
@export var procedural_floor_mesh: int = 1

func GenerateMap(map_name: String = ""):
	if map_name == "":
		CreateProceduralChunk()
	else:
		CreateMap(GetGridValues(map_name))


func CreateProceduralChunk() -> void:
	var section_type: String = section_selector.choose_and_register_category()
	var chunk_start_z: int = 0
	if maps_data_list.size() > 0:
		chunk_start_z = -(global_max_z + 1)

	var section_data: Dictionary = section_factory.build_section(
		section_type,
		procedural_last_exit_x,
		chunk_start_z,
		procedural_seed,
		next_chunk_id,
		procedural_floor_y,
		procedural_floor_mesh
	)

	procedural_last_exit_x = section_data["exit_x"]

	print("section #%d  type=%s  depth=%d  exit_x=%d  |  %s" % [
		count, section_data["type"], section_data["depth"], section_data["exit_x"],
		section_selector.debug_state()
	])

	var cell_data_list: Dictionary = {"cells": {}}
	for cell_data in section_data["cells"]:
		var cell: Vector3i = cell_data["cell"]
		var mesh: int = cell_data["mesh"]
		var orientation: int = cell_data["orientation"]
		cell_data_list["cells"][GetPositionAsString(cell)] = [cell, mesh, orientation]

	maps_data_list.append({
		"map_id": count,
		"map_name": "ProceduralSection_" + str(count) + "_" + section_type,
		"cell_data": cell_data_list,
		"map_instance": null
	})
	count += 1
	next_chunk_id += 1
	CreateMap(maps_data_list)

		
func CreateMapsNamesList() -> void:
	"""
	GERA UMA LISTA COM O NOME DE TODOS OS MAPAS
	"""
	var maps_scene_temp = maps_scene.instantiate()
	for map in maps_scene_temp.get_children():
		maps_names.append(map.get_name())
	maps_scene_temp.queue_free()

func GetGridValues(map_name) -> Array:
	"""
	RETORNA UMA LISTA COM OS VALORES DO GRID: CORDENADAS DA CELULA, QUAL MESH POSSUI E ROTACAO
	"""
	var map_instance = maps_scene.instantiate()
	var map = map_instance.get_node(map_name)
	var cells_coord_list = map.get_used_cells()
	var cells_orientation = GetCellOrientation(cells_coord_list, map)
	var mesh_list = GetMeshIndex(map.get_meshes())
	var cell_data_list:Dictionary = {"cells" : {}}
	var cell_position = ""
	for i in range(min(cells_coord_list.size(), mesh_list.size(), cells_orientation.size())):
		cells_coord_list[i].z -= global_max_z
		cell_position = GetPositionAsString(cells_coord_list[i])
		cell_data_list["cells"][cell_position] = [cells_coord_list[i], mesh_list[i], cells_orientation[i]]
	maps_data_list.append({"map_id": count, "map_name": map_name, "cell_data": cell_data_list, "map_instance": map})
	count += 1
	map_instance.queue_free()
	return maps_data_list

func GetPositionAsString(position):
	if position is Vector3 or position is Vector3i:
		return str(position.x)+""+str(position.y)+""+str(position.z)
	else:
		return str(position.x)+""+str(0)+""+str(position.y)
		

func GetCellOrientation(_coords, _map) -> Array:
	"""
	RETORNA A ORIENTACAO DAS CELULAS DO MAPA
	"""
	var cells_orientation_basis: Array = []
	for coord in _coords:
		cells_orientation_basis.append(_map.get_cell_item_orientation(coord))
	return cells_orientation_basis

func GetMeshIndex(meshes) -> Array:
	"""
	RETORNA UMA LISTA COM O INDEX DAS MESHES USADAS NO MAPA
	"""
	var mesh_indices:Array = []
	for i in range(meshes.size()):
		if i % 2 != 0:
			var mesh_name:String = GetMeshName(meshes[i])
			var mesh_index:int = FindMeshIndex(mesh_name)
			mesh_indices.append(mesh_index)
	return mesh_indices

func GetMeshName(mesh) -> String:
	"""
	RETORNA NOME DA MESH
	"""
	return mesh.get_name()

func GetMapInstanceById(ID: int):
	var map_instance
	for i in range(len(maps_data_list)):
		if ID == maps_data_list[i]["map_id"]:
			map_instance = maps_data_list[i]["map_instance"]
			break
	return map_instance

func GetMapById(ID: int):
	var map
	for i in range(len(maps_data_list)):
		if ID == maps_data_list[i]["map_id"]:
			map = maps_data_list[i]
			break
	return map

func CreateMap(map_value) -> void:
	"""
	RECEBE O DICIONARIO COM OS VALORES DO MAPA E INSTANCIA OS OBJETOS NO GRID 
	"""

	var map_id = map_value[count-1]["map_id"]
	var map_name = map_value[count-1]["map_name"]
	var section = GetMapInstanceById(map_id)
	
	var cells_position_list = map_value[count-1]["cell_data"]["cells"].keys()
	
	for i in range(0, len(cells_position_list)):
		
		var cell: 		 Vector3 = map_value[count-1]["cell_data"]["cells"][cells_position_list[i]][0]
		var mesh: 		 int = map_value[count-1]["cell_data"]["cells"][cells_position_list[i]][1]
		var orientation: int = map_value[count-1]["cell_data"]["cells"][cells_position_list[i]][2]
		
		match mesh:
			PLATFORM_FALLING_MESH:
				InstantiateObject(cell.x + 0.5 , cell.y, cell.z  + 0.5, mesh)
				gridmap.set_cell_item(Vector3(cell.x, cell.y, cell.z  ), mesh, orientation)
			WEB_MESH:
				InstantiateObject(cell.x + 0.5 , cell.y, cell.z  + 0.5, mesh)
				gridmap.set_cell_item(Vector3(cell.x, cell.y , cell.z  ), mesh, orientation)
			CHEST_MESH:
				InstantiateObject(cell.x + 0.5 , cell.y, cell.z  + 0.5, mesh, orientation)
				gridmap.set_cell_item(Vector3(cell.x, cell.y , cell.z  ), mesh, orientation)
			TELEPORTER_MESH:
				InstantiateObject(cell.x + 0.5, cell.y, cell.z + 0.5, mesh)
				gridmap.set_cell_item(Vector3(cell.x, cell.y, cell.z  ), mesh, orientation)
			SPIKE_MESH:
				InstantiateObject(cell.x + 0.5, cell.y + 0.2, cell.z  + 0.5, mesh)
				gridmap.set_cell_item(Vector3(cell.x, cell.y , cell.z  ), mesh, orientation)
				
			COIN_MESH: 			  InstantiateObject(cell.x + 0.5, cell.y - 0.2, cell.z + 0.5, mesh)
			SAW_MESH: 			  InstantiateObject(cell.x + 0.5, cell.y -0.75, cell.z  + 0.5, mesh)
			SPINNER_DOUBLE_MESH:  InstantiateObject(cell.x + 0.5, cell.y -0.75, cell.z  + 0.5, mesh)
			ARROW_SHOOTER_MESH:   InstantiateObject(cell.x, cell.y, cell.z  + 0.5, mesh, orientation)
			SLIME_SHOOTER_MESH:   InstantiateObject(cell.x + 0.5, cell.y + 0.6, cell.z + 0.5, mesh, orientation)
			PUSHER_MESH: 		  InstantiateObject(cell.x + 0.5, cell.y, cell.z + 0.5, mesh, orientation)
			FIRE_HORIZONTAL_MESH: InstantiateObject(cell.x + 0.5, cell.y, cell.z + 0.5, mesh, orientation)
			FIRE_CIRCLE_MESH: 	  InstantiateObject(cell.x + 0.5, cell.y, cell.z + 0.5, mesh, orientation)
			BAT_ON_SPOT_MESH: 	  InstantiateObject(cell.x + 0.5, cell.y - 1, cell.z + 0.5, mesh)
			BAT_CIRCLE_MESH: 	  InstantiateObject(cell.x + 0.5, cell.y - 1, cell.z + 0.5, mesh)
			SKELETON_MESH: 		  InstantiateObject(cell.x + 0.5, cell.y - 1, cell.z + 0.5, mesh)	
			GOLEM_MESH: 		  InstantiateObject(cell.x + 0.5, cell.y - 0.3, cell.z + 0.5, mesh)
			FIRE_SHOOTER_MESH: 	  InstantiateObject(cell.x + 0.5, cell.y + 0.6, cell.z + 0.5, mesh, orientation)
			ONE_FIRE_SHOOTER_MESH:  InstantiateObject(cell.x + 0.5, cell.y, cell.z + 0.5, mesh, orientation)
			ONE_SLIME_SHOOTER_MESH: InstantiateObject(cell.x + 0.5, cell.y + 0.6, cell.z + 0.5, mesh, orientation)
			_:
				gridmap.set_cell_item(Vector3(cell.x, cell.y , cell.z ), mesh, orientation)
	global_max_z = FindMaxZ()

func CalculateDistances(positions):
	
	var numPositions: int = positions.size()
	for i in range(numPositions):
		for j in range(numPositions):
			var dx: float = positions[i].x - positions[j].x
			var dy: float = positions[i].y - positions[j].y
			var dz: float = positions[i].z - positions[j].z
			var distance: float = sqrt(dx * dx + dy * dy + dz * dz) 
			if distance != 0:
				distances.append({"i": i, "tp_origin": positions[i], "tp_destiny": positions[j], "distance": distance})

func FindMaxZ() -> int:
	"""
	RETORNA O Z MAIS LONGE DO GRID( LINHA FINAL DO MAPA )
	"""
	var last_map = maps_data_list[(maps_data_list.size() - 1)]["cell_data"]["cells"]
	var keys_arr = last_map.keys()
	var max_z: int = 0 
	for i in range(len(keys_arr)):
		var cell_value = last_map[keys_arr[i]][0]
		if abs(cell_value.z) > max_z:
			max_z = abs(cell_value.z)
	return max_z

func FindMeshIndex(mesh) -> int:
	"""
	RETORNA O INDEX DA MESH
	"""
	return mesh_library.find_item_by_name(mesh)

func CheckNextPlayerPosition(_position) -> Array:
	"""
	VERIFICA A PROXIMA POSICAO DO PLAYER, CASO EXISTA CELULA ELE MOVE PRA ELA C.C ELE CAI
	RETORNA A CELULA PISADA E SE ELA EXISTE
	"""
	var cell_found: bool = false
	var cell
	var object: Object
	var position_string = GetPositionAsString(floor(_position))
	
	for i in range(len(maps_data_list)):
		if position_string in maps_data_list[i]["cell_data"]["cells"]:
			object = GetObjectInstance(Vector3(_position))
			cell_found = true
			cell = maps_data_list[i]["cell_data"]["cells"][position_string][1]
	if cell_found:
		return [cell_found, cell, object]
	else:
		return [cell_found, null, null]
	
func CheckNextPosition(target_position):
	var position_string: String = GetPositionAsString(floor(target_position))
	var cell_found: bool = false
	for i in range(len(maps_data_list)):
		var cells = maps_data_list[i]["cell_data"]["cells"]
		if GetPositionAsString(floor(target_position)) in maps_data_list[i]["cell_data"]["cells"]:
			
			cell_found = true
			break
	return cell_found	
	
func EraseCell(_position, _index) -> void:
	"""
	APAGA CELULA NAQUELA POSICAO
	"""
	for i in range(len(maps_data_list)):
		if GetPositionAsString(floor(_position)) in maps_data_list[i]["cell_data"]["cells"]:
			maps_data_list[i]["cell_data"]["cells"][GetPositionAsString(floor(_position))][1] = -1
			gridmap.set_cell_item(Vector3(_position.x -0.5, _position.y, _position.z - 1), -1)
			break
func PlatformFallingTimerTimeout(_position, index) -> void:
	"""
	FUNCAO CONECTADA COM O SINAL DE TIMEOUT DO TIMER
	"""
	EraseCell(_position, index)

func InstantiateAndAdd(mesh_scene, _x, _y, _z, mesh_index, orientation_data = null):
	var instance = mesh_scene.instantiate()
	instance.transform.origin = Vector3(_x, _y, _z)
	if orientation_data:
		instance.transform.basis = Basis(Vector3(0, 1, 0), deg_to_rad(orientation_data["rotation"]))
	add_child(instance)
	objects_instances.append({"position": Vector3(_x, _y, _z), "instance": instance, "mesh": mesh_index})
	return instance
	
func InstantiateObject(_x, _y, _z, mesh_index, mesh_orientation = null):
	var orientation_data: Dictionary = {
		
		0: 	{"rotation":	-90}, 	#PRA BAIXO	
		22: {"rotation":	180},	#ESQUERDA
		10: {"rotation":	 90}, 	#CIMA
		16: {"rotation":	  0}	#DIREITA

	}
	var scenes: Dictionary = {
		PLATFORM_FALLING_MESH: plataform_falling_scene,
		WEB_MESH: web_scene,
		CHEST_MESH: chest_scene,
		COIN_MESH: coin_scene,
		SAW_MESH: saw_scene,
		SPIKE_MESH: spike_scene,
		SPINNER_DOUBLE_MESH: spinner_double_scene,
		ARROW_SHOOTER_MESH: arrow_shooter_scene,
		SLIME_SHOOTER_MESH: slime_shooter_scene,
		TELEPORTER_MESH: teleporter_scene,
		PUSHER_MESH: pusher_scene,
		BAT_ON_SPOT_MESH: bat_on_spot_scene,
		BAT_CIRCLE_MESH: bat_circle_scene,
		SKELETON_MESH: skeleton_scene,
		FIRE_HORIZONTAL_MESH: esquentadinho_h_scene,
		FIRE_CIRCLE_MESH: esquentadinho_c_scene,
		GOLEM_MESH: golem_scene,
		FIRE_SHOOTER_MESH: fire_shooter_scene,
		ONE_FIRE_SHOOTER_MESH: one_fire_shooter_scene,
		ONE_SLIME_SHOOTER_MESH: one_slime_shooter_scene
	}
	if mesh_index == ARROW_SHOOTER_MESH:
		_x += 0.5
	var instance = InstantiateAndAdd(scenes[mesh_index], _x, _y, _z, mesh_index, orientation_data.get(mesh_orientation))
	if mesh_index == PLATFORM_FALLING_MESH:
		instance.connect("erase_platform_falling", PlatformFallingTimerTimeout.bind(instance.position, 0))
	if mesh_index == TELEPORTER_MESH:
		TeleporterIsInstancied(instance, _x,_y,_z)
	
func TeleporterIsInstancied(instance, _x,_y,_z) -> void:
	instance.UpdateShaderPosition(_x, _y, _z)
	var teleport_pos: Vector3i = Vector3i(_x, _y, _z)
	for pos in teleport_final:
		if pos != teleport_pos:
			var new_pos: Vector3 = Vector3(pos.x + 0.5, pos.y + 0.5, pos.z - 0.5)
			instance.tp_position = new_pos
		else:
			continue
	instance.position = Vector3(_x, _y, _z)
		
func LinkTeleportesByMinimumDistance():
	for object in objects_instances:
		if object["mesh"] == TELEPORTER_MESH:
			var temp_tp = object["instance"]
			var temp_pos = object["position"]
			temp_pos.x -= 0.5
			temp_pos.z += 0.5
			var minimun_dist: float = 999
			var connection
			for dist in distances:
				if dist["tp_origin"] == Vector3i(temp_pos.x, temp_pos.y,temp_pos.z):
					if dist["distance"] < minimun_dist:
						minimun_dist = dist["distance"]
						connection = dist["tp_destiny"]
			var connection_pos: Vector3 = connection
			connection_pos.x += 0.5
			connection_pos.y += 0.5
			connection_pos.z -= 0.5

			if connection:
				connection.z -= 0.5
				temp_tp.tp_position = connection_pos
			
func GetObjectInstance(_position):
	var object_to_return = null
	for object in objects_instances:
		if object["position"].x == _position.x and object["position"].z == _position.z:
			if object["instance"] != null and !object["instance"].is_queued_for_deletion():
				if is_instance_of(object["instance"], GOLEM): return object["instance"]
				object_to_return = object["instance"]
	return object_to_return
	
func UpdateObjectInstancePositionOnMapData(old_pos, new_pos):
	var obj_instance = GetObjectInstance(old_pos)
	for obj in objects_instances:
		if obj["instance"] == obj_instance:
			obj["position"] = new_pos
			return
func GetCellByPositionString(position:String):
	return maps_data_list[count]["cell_data"]["cells"][position]
	
func GetCellByMapIdAndPositionString(position:String, mapid: int):
	return maps_data_list[mapid]["cell_data"]["cells"][position]

func ResetMap():
	for object in objects_instances:
		if object["instance"] != null and !object["instance"].is_queued_for_deletion():
			object["instance"].queue_free()
	objects_instances = []
	gridmap.clear()
	global_max_z = 0
	distances = []
	teleport_final = []
	count = 0
	next_chunk_id = 0
	maps_data_list = []
	procedural_last_exit_x = 22
	if section_selector != null:
		section_selector.reset()

func Init():
	level = 0
	procedural_last_exit_x = 22

	randomize()
	procedural_seed = randi()
	section_factory = section_factory_script.new()

	add_child(section_selector)
	section_selector.reset()

	GenerateMap("Base")

func RemoveDistantMap():
	var oldest_map = maps_data_list[0]
	for cell in oldest_map["cell_data"]["cells"]:
		var obj_pos = Vector3(oldest_map["cell_data"]["cells"][cell][0].x + 0.5,oldest_map["cell_data"]["cells"][cell][0].y, oldest_map["cell_data"]["cells"][cell][0].z + 0.5)
		var object_to_remove = GetObjectInstance(obj_pos)
		if object_to_remove != null:
			gridmap.set_cell_item(oldest_map["cell_data"]["cells"][cell][0], -1)
			object_to_remove.queue_free()
		gridmap.set_cell_item(oldest_map["cell_data"]["cells"][cell][0], -1)
	maps_data_list.pop_front()
	count = count - 1
