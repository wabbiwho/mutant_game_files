
extends Node2D

@onready var inventory_ui = $UI/Inventory

func _ready():
	GameManager.spawn_player(self, Vector2(100, 200))
	#inventory_ui.hide()
func _input(event):
	#if event.is_action_pressed("open_inv"):
		#inventory_ui.visible = not inventory_ui.visible
		#get_tree().paused = inventory_ui.visible
	pass
