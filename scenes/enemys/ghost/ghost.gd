extends Area3D

@onready var player = $".."
@onready var world_environment = $"../../WorldEnvironment"
enum {CHASING, IDLE, TELEPORTING}

var player_around_light
var fix_position:   Vector3
var min_trauma: 	float = 0.0 
var max_trauma: 	float = 0.075
var max_distance: 	float = 10.0
var red:			Color = Color(255,0,0,1)
var white :			Color = Color(1,1,1,1)
var weight: 		float = 0.00005
var chase_speed:	float = 1
var state:				  = IDLE

func _ready():
	GetPlayerLight()
	fix_position = global_position
	
func GetPlayerLight():
	player_around_light = player.get_child(5)
	
func _process(delta):
	if !player.game_started:
		return
	
	var distance:float = floor(sqrt((position.x - player.position.x)**2 + (position.z - player.position.z)**2))
	#if distance > 15:
		#fix_position.z = player.position.z + 15
		#UpdatePosition()
	if player.timer.time_left < 995.0 and player.first_move and player.timer.time_left != 0:
		if state == TELEPORTING: return
		ChasePlayer(delta)
	elif player.first_move:
		if state == TELEPORTING: return
		StopChase(delta)

func UpdatePosition():
	position = fix_position
	state = IDLE
	
func ChasePlayer(delta):
	if !player.player_died:
		var distance:float = sqrt((position.x - player.position.x)**2 + (position.z - player.position.z)**2)
		var distance_factor = clamp(distance / max_distance, 0.0, 1.0)
		player.trauma_value = min_trauma + (max_trauma - min_trauma) * (1.0 - pow(distance_factor, 2.0))
		var ambient_intensity = 1.0 - player.trauma_value

		var target_color: Color = Color(player.trauma_value, player.trauma_value, player.trauma_value)
		world_environment.environment.ambient_light_color = world_environment.environment.ambient_light_color.lerp(target_color, 0.005 * delta)
		player_around_light.light_color = player_around_light.light_color.lerp(red, weight * delta)

		var target_range: float = 3.0
		player_around_light.omni_range = lerp(player_around_light.omni_range, target_range, 0.05 * delta)
		var direction = (player.position - position).normalized()
		position = position.lerp(player.position, chase_speed * delta)
		#position += chase_speed * delta

func StopChase(delta):
	if !player.player_died:
		var distance: float = sqrt((position.x - player.position.x)**2 + (position.z - player.position.z)**2)
		var distance_factor: float= clamp(distance / max_distance, 0.0, 1.0)
		var inverse_factor: float = 1.0 - distance_factor
		player.trauma_value = min_trauma + (max_trauma - min_trauma) * pow(inverse_factor, 2.0)
		
		var ambient_intensity:float = 1.0 - player.trauma_value
		var target_color: Color = Color(ambient_intensity, ambient_intensity, ambient_intensity)
		world_environment.environment.ambient_light_color = world_environment.environment.ambient_light_color.lerp(target_color, 0.05 * delta)
		player_around_light.light_color = lerp(player_around_light.light_color, white, 0.1 * delta )
		
		var target_range: float = 5.0
		player_around_light.omni_range = lerp(player_around_light.omni_range, target_range, 0.1 * delta)
		position = position.lerp(fix_position, 0.001)

#func _on_collision_body_entered(body):
	#ENEMY.KillPlayer(body)


func _on_rigid_body_3d_body_entered(body):
	print(body)
	pass # Replace with function body.

