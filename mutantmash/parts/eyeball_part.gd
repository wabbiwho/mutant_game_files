extends Node2D

@export var bob_amplitude := 2.0  # Pixels
@export var bob_speed := 3.0

var time_offset := 0.0
var base_position := Vector2.ZERO

func _ready():
	base_position = position
	time_offset = randf() * PI * 2
#
#func _process(delta):
	#var bob = sin(Time.get_ticks_msec() / 1000.0 * bob_speed + time_offset) * bob_amplitude
	#position = base_position + Vector2(0, bob)
