extends CharacterBody3D
class_name PLAYER
@export var character: Character
@onready var grid_map = $"../GridMap"
@onready var face_direction = $FaceDirection
@onready var timer = $IdleTimer

###FAZER UM STATE MACHINA PRO PLAYER -> IDLE MOVING FALLING E DEAD!!!!!
var player_character: Node = null
var starting_position:= Vector3(22.5, 0.3, -0.5)
var over_trap: 		bool = false
var is_moving: 		bool = false
var is_falling: 	bool = false
var is_teleporting: bool = false
var can_move: 		bool = true	
var game_started: 	bool = false ###MUDAR ISSO AQUI
var first_move:		bool = false
var player_died:	bool = false
#var slime_on_face: 	bool = false
var animation_player: AnimationPlayer
var trauma_value: float = 0.0
var coins: 		int = 0
var distance: 	int = 0
var highscore: 	int
var threshold: int = 0

signal coin_collected
signal update_distance
signal update_highscore
signal player_moved
signal player_moved_first_time
signal power_percentage_update

const MOVEMENT_DURATION:	  float = 0.175
const FALL_ANIM_DURATION:	  float = 1.0
const SCALE_ANIM_DURATION: 	  float = 0.25
const POSITION_ANIM_DURATION: float = 0.5
const SCALE_ZERO 	= Vector3(0,0.05,0)
const SCALE_NORMAL 	= Vector3(1,1,1)


@onready var world_enviroment = $"../WorldEnvironment".environment

func _ready():
	$AroundLight.light_energy = 0.0
	$"../WorldEnvironment".environment.ambient_light_energy = 0
	UpdateCharacter()
	$"../HUD".connect("use_power", PowerUsed)
	$"../HUD".connect("power_up",  PowerIsUp)
	#player_character.connect("tree_exited", _on_node_exit_tree)
	
func PowerIsUp():
	if !player_character.can_use_power: 
		player_character.can_use_power = true
	
func PowerUsed():
	player_character.ActiveAbility(player_character.getAbilityLevel())
	power_percentage_update.emit(player_character.ResetAbilityPercentage())
	$"../HUD".ResetPowerPercentageRadial(player_character.ability_reset_time)
	
func AddCollisionToPlayer():
	var character_collision_shape = player_character.get_child(2)
	if character_collision_shape:
		$CollisionShape3D.shape = character_collision_shape.shape
		$CollisionShape3D.scale = character_collision_shape.scale
		$CollisionShape3D.position.y = 0.5
		player_character.remove_child(character_collision_shape)
		character_collision_shape.queue_free()

func _process(_delta):
	if player_died or !game_started: return
	#if player_character:
	if grid_map.get_cell_item(Vector3(player_character.position.x, player_character.position.y, player_character.position.z - 1)) == -1 && !is_moving && !is_falling && !is_teleporting:
			Fall()
	if is_instance_of(player_character, BLAZE):   BlazeFillAbilityMethod()
	
func DistanceZFromStartingPosition() -> void:
	"""
	PEGA O Z DO PLAYER E FAZ ALGUMAS VERIFICACOES DE UPDATES
	"""
	distance = abs(position.z - starting_position.z)
	update_distance.emit(distance) #HUD
	if distance > highscore:
		Settings.SaveHighScore(distance)
		highscore = Settings.LoadHighScore()
		update_highscore.emit() #HUD
	
func _input(_event):
	if is_moving or !game_started or is_falling or !can_move or player_died or is_teleporting: return
	if Input.is_action_just_pressed("up"):
		await Move(Vector2.UP)
	elif Input.is_action_just_pressed("down"):
		await Move(Vector2.DOWN)
	elif Input.is_action_just_pressed("left"):
		await Move(Vector2.LEFT)
	elif Input.is_action_just_pressed("right"):
		await Move(Vector2.RIGHT)
		
func Move(direction: Vector2, external_force: bool = false) -> void:
	if is_moving: return
	"""
	MOVE O PLAYER PARA O TILE DE DIRECAO PRETENDIDA
	"""
	is_moving = true

	if !first_move:
		first_move = true
		trauma_value = 0
		player_moved_first_time.emit()
		
	if grid_map.count > 4:
		grid_map.RemoveDistantMap()
		threshold = distance
	
	var target_position: Vector3 = player_character.transform.origin + TransformVector2ToVector3(direction)
	player_character.rotation_degrees.y = GetAngleToDirection(direction)
	face_direction.rotation_degrees.y = GetAngleToDirection(direction)
	
	var direction_str: String = getDirectionByName(direction)
		
	if IsNextPositionCollision(external_force, direction_str): return
	
	var next_position_values: Array = grid_map.CheckNextPlayerPosition(target_position)
	
	CreateNextMap(target_position)

	VerifyNextPositionAndMove(next_position_values, direction, target_position)

func IsNextPositionCollision(external_force: bool ,direction: String) -> bool:
	
	var collisions: Dictionary = {
		"down": $StaticBodyDetectionGroup/StaticBodyDetection.is_colliding(),
		"left": $StaticBodyDetectionGroup/StaticBodyDetection2.is_colliding(),
		"up": $StaticBodyDetectionGroup/StaticBodyDetection3.is_colliding(),
		"right": $StaticBodyDetectionGroup/StaticBodyDetection4.is_colliding()
	}
	
	if !external_force:
		if collisions[direction]:
			is_moving = !is_moving
			return true
	return false


func VerifyNextPositionAndMove(next_position_values: Array, direction: Vector2, next_position: Vector3) -> void:	
	
	var verify_fall: bool = next_position_values[0]
	#var mesh_index = next_position_values[1]
	var object_instance: Object = next_position_values[2]

	await CheckIfStaticBody3DIsNextPosition(object_instance, direction, next_position)

	if !verify_fall: Fall()
	if player_died: return
	if animation_player: animation_player.play("idle")
	DistanceZFromStartingPosition()
	player_moved.emit(direction)
	is_moving = false
	
func TeleportPlayer(_x, _y, _z):
	$AudioListener3D.clear_current()
	is_teleporting = true
	$CollisionShape3D.disabled = true
	if Settings.enable_sound: $TeleportSFX.play()
	
	await DEScaleAnimation($".", player_character)
	
	await PositionAnimation($".", player_character, Vector3(_x, _y, _z))
	
	await UPScaleAnimation($".", player_character)
	
	is_teleporting = false
	$CollisionShape3D.disabled = false
	$AudioListener3D.make_current()

func CreateNextMap(player_map_position: Vector3):
	if ceil(abs(player_map_position.z)) >= (grid_map.global_max_z - 10):
		grid_map.GenerateMap()
		#grid_map.RemoveDistantMap()

func CheckIfStaticBody3DIsNextPosition(object_instance, direction: Vector2, next_position: Vector3) -> void:
	var move_forward: bool
	if is_instance_valid(object_instance): 
		if object_instance.get_class() == "StaticBody3D":
			if is_instance_of(object_instance, CHEST) and object_instance.has_method("OpenChest"):
				move_forward = false
				object_instance.OpenChest()
			if is_instance_of(object_instance, GOLEM) and object_instance.has_method("Move"):
				var old_pos: Vector3 = object_instance.position
				var new_pos: Vector3 = await object_instance.Move(direction)
				grid_map.UpdateObjectInstancePositionOnMapData(old_pos, new_pos)
				move_forward = false

	if !object_instance or (object_instance and object_instance.get_class() != "StaticBody3D" or move_forward):
		await AnimateMove(next_position)
	
func AnimateMove(next_position):
	if animation_player:
		if Settings.enable_sound: $JumpSFX.play()
		animation_player.play("walk")
		$CPUParticles3D.emitting = true
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($".", "position", next_position, 0.075)
	tween.parallel().tween_property(player_character, "position", next_position, 0.075)
	await tween.finished

func getDirectionByName(direction: Vector2) -> String:
	var direction_str: String = ""
	if direction == Vector2(0, 1):
		direction_str = "down"
	elif direction == Vector2(0, -1):
		direction_str = "up"
	elif direction == Vector2(-1, 0):
		direction_str = "left"
	elif direction == Vector2(1, 0):
		direction_str = "right"

	return direction_str

func DEScaleAnimation(player, character):
	var tween:Tween = await  MakeTeleportAnimation(player, character, "scale", SCALE_ZERO)
func PositionAnimation(player, character, TARGET_POSITION):
	var tween:Tween = await MakeTeleportAnimation(player, character, "position", TARGET_POSITION)
	Move(Vector2.UP)
	
func UPScaleAnimation(player, character):
	var tween:Tween = await MakeTeleportAnimation(player, character, "scale", SCALE_NORMAL)
	
func MakeTeleportAnimation(player, character, property ,final_value) -> Tween:
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_BOUNCE)
	tween.parallel().tween_property(player, property, final_value, SCALE_ANIM_DURATION)
	tween.parallel().tween_property(character,  property, final_value, SCALE_ANIM_DURATION)
	await tween.finished

	return tween

func TransformVector2ToVector3(direction: Vector2) -> Vector3:
	return Vector3(direction.x, 0, direction.y )

func GetAngleToDirection(direction: Vector2) -> float:
	"""
	PEGA A ROTACAO A PARTIR DA DIRECAO, FUNCIONA mas da pra melhorar isso aqui!
	"""
	if direction.y == -1:
		return 180
	elif direction.y == 1:
		return 0
	elif direction.x == -1:
		return -90
	elif direction.x == 1:
		return 90
	else:
		return 0
		
func GetAnimationPlayer():
	for child in player_character.get_children():
		if child is AnimationPlayer:
			return child

func _on_screens_manager_game_started() -> void:
	game_started = true

func CollectCoin(value) -> void:
	if player_character.has_method("MoreGoldPassive"):
		var gold_multiplier: float = player_character.MoreGoldPassive(player_character.getPassiveLevel())
		value *= gold_multiplier
		RobotFillAbilityMethod(value)
	coins += value
	$"../ScreensManager/GameOverScreen/MarginContainer/VBoxContainer/Panel/HBoxContainer/Control4/CoinLabel".text = "Moedas Coletadas: " + str(coins) 
	Settings.SaveCoins(coins)
	if Settings.enable_sound: $CoinSFX.play()
	coin_collected.emit(coins) #HUD

func Fall() -> void:
	is_falling = true
	if Settings.enable_sound: $FallSFX.play()
	$CollisionShape3D.disabled = true
	await FallAnimation()
	is_falling = false
	player_died = true
	
	ReloadScene()

func FallAnimation():
	var tween:Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUINT)
	var rotation_position:Vector3 =  Vector3(deg_to_rad(-90), deg_to_rad(180), deg_to_rad(-90))
	tween.parallel().tween_property(player_character, "position:y", player_character.position.y - 20, FALL_ANIM_DURATION)
	tween.parallel().tween_property(player_character, "rotation", rotation_position, 1)
	await tween.finished
	
func Die() -> void:
	$CollisionShape3D.disabled = true
	if animation_player:
		if Settings.enable_sound: $DieSFX.play()
		animation_player.play("die")
	else:
		print("morreu")
	
"""ISSO AQUI TA CONECTADO COM O FINAL DE CADA ANIMACAO, FUNCIONA MAS NAO EH O JEITO CERTO DE SE FAZER"""
func AnimationFinished(animation_name) -> void:
	if animation_name == "die":
		ReloadScene()
		
func AnimationStarted(animation_name) -> void:
	if animation_name == "die":  player_died = true
	if animation_name == "idle": timer.start()
		
func ReloadScene() -> void:
	grid_map.ResetMap()
	$".".visible = false
	SetDefaultPosition()
	game_started = false
	ShowGameOverScreen()
	
func ShowGameOverScreen() -> void:
	$"../HUD".hide()
	$"../ScreensManager".change_screen($"../ScreensManager/GameOverScreen")
	
func UpdateCharacter():
	if player_character:
		player_character.queue_free()
	player_character = character.scene.instantiate()
	Store.CURRENT_CHARACTER = player_character.name
	add_child(player_character)
	transform.origin = starting_position
	player_character.set_as_top_level(true)
	animation_player = GetAnimationPlayer()
	PlayIdleAnimation()
	AddCollisionToPlayer()

func PlayIdleAnimation():
	if animation_player:
		animation_player.play("idle")
		animation_player.animation_finished.connect(AnimationFinished)
		animation_player.animation_started.connect(AnimationStarted)

func RobotFillAbilityMethod(value: int) -> void:
	power_percentage_update.emit(player_character.FillAbilityRadial(value)) #HUD

func BlazeFillAbilityMethod() -> void:
	if player_character.can_use_power: return
	power_percentage_update.emit(player_character.FillAbilityRadial()) #HUD
	
func PlayerLightOff():
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($AroundLight, "light_energy", 0, 0.5)
	tween.parallel().tween_property(world_enviroment, "ambient_light_energy", 0, 0.5)
	
func PlayerLightOn():
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_EXPO)
	tween.parallel().tween_property($AroundLight, "light_energy", 1, 0.5)
	tween.parallel().tween_property(world_enviroment, "ambient_light_energy", 0.1, 0.5)
	#await tween.finished

func InitPlayer():
	#if player_character and is_instance_valid(player_character):
		#player_character.queue_free()
	$".".visible = true
	$"../CameraOrtogonal".ResetCamera()
	$AroundLight.light_energy = 0.0
	$"../WorldEnvironment".environment.ambient_light_energy = 0
	UpdateCharacter()
	#$"../HUD".connect("use_power", PowerUsed)
	#$"../HUD".connect("power_up",  PowerIsUp)
	$CollisionShape3D.disabled = false
	player_died = false
	is_moving = false
	is_falling = false
	is_teleporting = false
	can_move = true
	game_started = false
	first_move = false
	coins = 0
	distance = 0
	trauma_value = 0
	threshold = 0
	highscore = Settings.LoadHighScore()
	coin_collected.emit(coins)
	update_distance.emit(distance)
	update_highscore.emit()
	$TraumaHandler.ResetTrauma()
	$"../HUD".ResetPlayerHabilities()

func SetDefaultPosition():
	transform.origin = starting_position
	player_character.position = starting_position
	player_character.rotation_degrees.y = 0
	face_direction.rotation_degrees.y = 0
