extends Node

@onready var player = $".."
@onready var world_environment = $"../../WorldEnvironment"
@onready var idle_timer = $"../IdleTimer"
@onready var player_around_light = $"../AroundLight"

enum {CHASING, IDLE, TELEPORTING}

var min_trauma: float = 0.0 
var max_trauma: float = 0.15
var red: Color = Color(1, 0, 0, 1)
var white: Color = Color(1, 1, 1, 1)
var black: Color = Color(0, 0, 0, 1)
var weight: float = 0.00005
var chase_speed: float = 1
var state: int = IDLE
var trauma_value: float = 0.0
var max_idle_time: float = 10.0
var trauma_multiplier: float = 10.0
var active_counter: int = 0
var max_counter: int = 3
var trauma_activated: bool = false
var apply_speed: float = 0.075
var unapply_speed: float = 0.075

func _process(delta):
	pass

	if !player.game_started: return
	if player.trauma_value >= max_trauma:
		player.Die()
		ResetTrauma()
		return
	if player.timer.time_left < 12.5 and player.first_move and player.timer.time_left != 0:
		if !trauma_activated:
			if active_counter < max_counter: 
				active_counter += 1
			trauma_activated = true
		ApplyTrauma(delta)
	else:
		trauma_activated = false
		UnapplyTrauma(delta)

func ApplyTrauma(delta):
	if !player.player_died:
		var time_factor: float = clamp(1.0 - (idle_timer.time_left / max_idle_time), 0.0, 1.0)
		player.trauma_value =  lerp(player.trauma_value, max_trauma, delta/active_counter * time_factor)
		#player.trauma_value = min_trauma + (max_trauma - min_trauma) * time_factor * active_counter

		var ambient_intensity = 1.0 - player.trauma_value
		world_environment.environment.ambient_light_color = world_environment.environment.ambient_light_color.lerp(black, apply_speed * delta)
		player_around_light.light_color = player_around_light.light_color.lerp(red, apply_speed * delta)

		var target_range: float = 3.0
		player_around_light.omni_range = lerp(player_around_light.omni_range, target_range, apply_speed * delta)

func UnapplyTrauma(delta):
	if !player.player_died and player.trauma_value > 0:
		player.trauma_value = lerp(player.trauma_value, min_trauma, delta/active_counter)
		var ambient_intensity: float = 1.0 - player.trauma_value
		var target_color: Color = Color(ambient_intensity, ambient_intensity, ambient_intensity)
		world_environment.environment.ambient_light_color = world_environment.environment.ambient_light_color.lerp(target_color, delta/active_counter)
		player_around_light.light_color = player_around_light.light_color.lerp(white, delta/active_counter)
		var target_range: float = 5.0
		player_around_light.omni_range = lerp(player_around_light.omni_range, target_range, delta/active_counter)

func ResetTrauma():
	active_counter = 0
	player.trauma_value = 0.0
	world_environment.environment.ambient_light_color = white
	player_around_light.light_color = white
	player_around_light.omni_range = 5.0

func _on_idle_timer_timeout():
	if player.first_move and !player.player_died:
		player.Die()
		ResetTrauma()
	else:
		return
