extends Resource
class_name Power
@export var id: String
@export var name: String
@export var description: String
@export var type: String = "passive" # "passive" or "active"
@export var icon: Texture2D
@export var input_combo: String
@export var cooldown: float
@export var cast_time: float
@export var resource_cost := {}
@export var tags := []
@export var input_slot := "attack_a"  # e.g., "attack_a", "ranged_b", "special_a"
