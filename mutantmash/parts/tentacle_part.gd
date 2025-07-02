extends Node2D

@export var max_rotation_deg := 15.0
@export var swing_speed := 2.0
@export var facing_angle := deg_to_rad(180)
 # Adjust based on how the sprite is drawn

var move_direction := 1
var time_offset := 0.0

func _ready():
	time_offset = randf() * PI * 2

func _process(delta):
	var wiggle = sin(Time.get_ticks_msec() / 1000.0 * swing_speed + time_offset) * deg_to_rad(max_rotation_deg)
	var base_dir = facing_angle + deg_to_rad(180) * -move_direction
	rotation = base_dir + wiggle

func set_move_direction(dir: int):
	move_direction = clamp(dir, -1, 1)
