extends Node2D

@export var twitch_angle_deg := 3.0
@export var twitch_interval := 1.5

var base_rotation := 0.0
var time_accum := 0.0

func _ready():
	base_rotation = rotation

func _process(delta):
	time_accum += delta
	if time_accum > twitch_interval:
		time_accum = 0
		var twitch = deg_to_rad(randf_range(-twitch_angle_deg, twitch_angle_deg))
		rotation = base_rotation + twitch
