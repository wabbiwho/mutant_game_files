extends Node

var player_scene := preload("res://player/player.tscn")
var curr_body: CharacterBody2D = null

var equipped_parts: Dictionary = {}

func _recursive_find_node(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node

	for child in node.get_children():
		if child is Node:
			var found = _recursive_find_node(child, target_name)
			if found:
				return found

	return null

func refresh_player_equipment():
	if curr_body:
		curr_body.clear_parts()
		curr_body.load_parts_from_data(equipped_parts)

func spawn_player(target_scene: Node, position: Vector2):
	pass
#
