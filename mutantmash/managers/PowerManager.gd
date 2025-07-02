extends Node

## A dictionary to store parts by group name (like "a", "b", etc.)
var part_registry := {}
@export var attack_group := "a"  # You can set this per instance in the editor!

func _ready():
	PowerManager.register_part(attack_group, self)
	part_registry.clear()  # Just in case we reload

## Called by parts when they spawn in
func register_part(group_id: String, part: Node) -> void:
	if not part_registry.has(group_id):
		part_registry[group_id] = []
	part_registry[group_id].append(part)

## Optional: to reset between levels or player deaths
func clear_registry():
	part_registry.clear()

## Called when player presses "A", "B", etc.
func trigger_attack_group(group_id: String) -> void:
	if not part_registry.has(group_id):
		print("No parts in group:", group_id)
		return

	for part in part_registry[group_id]:
		if part.has_method("trigger_attack"):
			part.trigger_attack()
