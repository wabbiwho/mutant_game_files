extends Node

# Exposed so you can tweak in the inspector if needed
@export var inventory_scene: PackedScene = preload("res://inventory/Inventory.tscn")

var inventory_ui: Control

func _ready():

	# Ensure we’re in the scene tree
	if get_parent() == null:
		get_tree().get_root().add_child(self)

	get_tree().get_root().add_child(self)  # 👈 This is key for input
	set_process_input(true)                # Make sure input is received

	var canvas = CanvasLayer.new()
	canvas.name = "UI"
	canvas.layer = 1
	add_child(canvas)

	inventory_ui = inventory_scene.instantiate()
	canvas.add_child(inventory_ui)
	inventory_ui.name = "Inventory"
	inventory_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	inventory_ui.visible = false

func _enter_tree():
	get_tree().get_root().add_child(self)
	set_process_input(true)
	set_process_unhandled_input(true)
	set_process_priority(100)  # ensures it's checked before Control nodes

func _input(event):
	if event.is_action_pressed("open_inv"):
		print("[UIManager] Tab pressed!")
		inventory_ui.visible = not inventory_ui.visible
		print("Inventory is now visible:", inventory_ui.visible)

		var scene = get_tree().current_scene
		var world = scene.get_node_or_null("GameWorld")
		if world:
			world.process_mode = Node.PROCESS_MODE_DISABLED if inventory_ui.visible else Node.PROCESS_MODE_INHERIT
