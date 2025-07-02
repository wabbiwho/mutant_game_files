extends TextureButton

var part_name: String
var part_texture: Texture
@export var cost: int = 0

@onready var inventory = $"../../"  # Adjust path to Inventory if needed
@onready var cost_label = $CostLabel

func _ready():
	texture_normal = part_texture
	cost_label.text = "🧬⧖" + str(cost)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		inventory.start_dragging_part(part_name)
