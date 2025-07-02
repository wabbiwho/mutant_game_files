extends TextureRect

signal part_dragged(cell_position)  # Emits signal when a part is dragged
signal part_dropped(cell_position)  # Emits signal when a part is dropped

@onready var highlight = $Highlight  # Reference to hover effect
@onready var grid_parent = $GridParent


var is_occupied = false  # Tracks if a part is in this cell
var part_name = ""  # Stores the name of the part in the cell
var is_dragging = false  # Tracks if the part is being dragged
var inventory_controller: Node = null

func _ready():
	#print("InventoryCell ready, class: ", get_class())
	highlight.modulate.a = 0.0  # Ensure highlight starts hidden
	connect("gui_input", Callable(self, "_on_gui_input"))  # Detect mouse input
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))  # Detect hover
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))  # Detect exit


func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT and is_occupied:  # Start dragging
			is_dragging = true
			emit_signal("part_dragged", self.position)

		elif event.is_released() and is_dragging:  # Detect mouse release properly
			is_dragging = false
			emit_signal("part_dropped", self.position)

func _on_mouse_entered():
	modulate = Color(1.1, 1.1, 1.1)

func _on_mouse_exited():
	modulate = Color(1, 1, 1)
