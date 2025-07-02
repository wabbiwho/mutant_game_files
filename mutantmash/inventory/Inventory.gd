extends Control

@onready var grid_parent = $GridContainer/GridParent
@onready var placed_parts_container = $GridContainer/PlacedPartsContainer

const CELL_SIZE = 64

var dragged_part = null
var drag_offset = Vector2.ZERO
var original_part_origin = null  # Expected to be a Vector2i representing grid origin
var original_rotation_step = 0   # Rotation as originally placed (0:0°, 1:90°, etc.)
var current_rotation_step = 0    # Current rotation for the ghost
var highlighted_cells = []
var inventory_controller


# New variable to store the part type being dragged.
var dragged_part_type = ""

# Define body parts.
# The "size" matrix uses 1 for valid cells.
var body_parts = {
	"Tentacle": {
		"size": [[1, 1], [0, 1]],
		"texture": preload("res://parts/Tenticle1_inv.png"),
		"cost": 50,
		"powers": []
	},
	"EyeStalks": {
		"size": [[1, 0, 1], [1,0, 1], [1, 0, 1], [1, 1, 1]],
		"texture": preload("res://parts/EyeStalks.png"),
		"cost": 50,
		"powers": []
	},
	"RobotArm": {
		"size": [[0, 1], [1, 1]],
		"texture": preload("res://parts/robot_arm.png"),
		"cost": 75,
		"powers": []
	},
	"AlienHead": {
		"size": [[1, 1], [1, 1]],
		"texture": preload("res://parts/AlienBorg_head.png"),
		"cost": 100,
		"powers": []
	},
	"Leggy": {
		"size": [[1, 1], [1, 0],[1, 0]],
		"texture": preload("res://parts/leggy.png"),
		"cost": 100,
		"powers": [ preload("res://powers/high_jump.tres") ]
	},
	"Eyeball": {
		"size": [[1]],
		"texture": preload("res://parts/eyeball_part.png"),
		"cost": 25,
		"powers": []
	}
}


var inventory_shape = [
	[0, 0, 0, 0, 0, 1, 1, 0, 0, 0, 0],
	[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
	[0, 0, 0, 0, 1, 1, 1, 0, 0, 0, 0],
	[0, 0, 0, 1, 1, 1, 1, 1, 0, 1, 1],
	[0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
	[1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0],
	[1, 1, 0, 1, 1, 1, 1, 1, 0, 0, 0],
	[0, 0, 0, 0, 1, 1, 1, 1, 0, 0, 0],
	[0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0], #2 8 , 4 10
	[0, 0, 0, 1, 1, 0, 1, 1, 1, 0, 0],
	[0, 0, 1, 1, 1, 0, 0, 1, 1, 1, 0] #6 8  9 10
]


func _ready():
	print("*=[DEBUG] Inventory node instance: ", self.get_instance_id())

	generate_inventory()
	populate_palette()
	# Spawn Tentacle in first valid cell.
	var start1 = find_empty_cell()  # Vector2i or null.
	if start1 != null:
		place_part("Tentacle", start1, 0)
	# Spawn RobotArm in next valid cell.
	var start2 = find_empty_cell()
	if start2 != null:
		place_part("RobotArm", start2, 0)
	var start3 = find_empty_cell()
	if start3 != null:
		place_part("Eyeball", start3, 0)
	var start4 = find_empty_cell()
	if start4 != null:
		place_part("Eyeball", start4, 0)
		
func _input(event):
	if dragged_part and event is InputEventMouseButton and not event.pressed:
		_on_part_dropped(get_global_mouse_position())


func _unhandled_input(event):
	if event.is_action_pressed("open_inventory"):
		GameManager.toggle_inventory()
		return
		
	if dragged_part and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		_on_part_dropped(get_global_mouse_position())


	# Rotate the dragged part when pressing 'R'.
	if dragged_part and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			current_rotation_step = (current_rotation_step + 1) % 4
			redraw_dragged_part()


# Helper: Transpose a 2D array.
func transpose(arr: Array) -> Array:

	var result = []
	if arr.size() == 0:
		return result
	var num_cols = arr[0].size()
	for i in range(num_cols):
		var new_row = []
		for row in arr:
			new_row.append(row[i])
		result.append(new_row)
	return result

# Rotate a given matrix (the shape) 90° clockwise for the given number of steps.
func rotate_shape(shape: Array, steps: int) -> Array:
	var rotated = shape.duplicate(true)
	for i in range(steps):
		rotated = transpose(rotated)
		for row in rotated:
			row.reverse()
	return rotated

# Return the bounding box (in cell units) from the full matrix.
func get_bounding_box(body_part: Dictionary, rotation_step: int) -> Vector2:
	var shape = rotate_shape(body_part["size"], rotation_step)
	var width = shape[0].size()
	var height = shape.size()
	return Vector2(width, height)

func generate_inventory():

	for y in range(inventory_shape.size()):
		for x in range(inventory_shape[y].size()):
			if inventory_shape[y][x] == 1:
				var cell = preload("res://inventory/InventoryCell.tscn").instantiate()
				cell.position = Vector2(x, y) * CELL_SIZE

				# Tag cell with its corresponding region.
				# Create the cell's grid coordinate.
				var grid_coord = Vector2i(x, y)
				var assigned = false
				# Loop over each region defined in TorsoData.anchors.
				for region_name in CustTorsoData.anchors.keys():
					if grid_coord in CustTorsoData.anchors[region_name]:
						cell.set_meta("region", region_name)
						assigned = true
						break
				# If no match was found, default to "belly".
				if not assigned:
					cell.set_meta("region", "belly")

				grid_parent.add_child(cell)
				cell.texture = preload("res://inventory/Cell1.png")
				cell.connect("part_dragged", Callable(self, "_on_part_dragged"))
				cell.connect("part_dropped", Callable(self, "_on_part_dropped"))
				cell.set("inventory_controller", self)


func _on_part_dragged(cell_pos: Vector2):
	# 1) Which cell did we click?
	var grid_click = Vector2i(int(cell_pos.x / CELL_SIZE), int(cell_pos.y / CELL_SIZE))
	var clicked_cell = find_cell(grid_click.x, grid_click.y)
	if clicked_cell == null or not clicked_cell.is_occupied:
		return

	# 2) Read its metadata
	dragged_part_type      = clicked_cell.part_name
	original_rotation_step = int(clicked_cell.get_meta("rotation_step", 0))
	original_part_origin   = clicked_cell.get_meta("part_origin")
	drag_offset            = Vector2(grid_click) - Vector2(original_part_origin)

	# 3) Remove it from the grid & refund
	clear_part(dragged_part_type, original_part_origin, original_rotation_step)

	# 4) Immediately rebuild GameManager.equipped_parts and refresh the player
	update_equipment()
	GameManager.refresh_player_equipment()

	# 5) Now spawn the ghost in its place
	current_rotation_step = original_rotation_step
	redraw_dragged_part()


# Redraw the ghost for dragging.
func redraw_dragged_part():
	if dragged_part_type == "" or not body_parts.has(dragged_part_type):
		return  # nothing to draw

	if dragged_part:
		dragged_part.queue_free()


	# Compute bounding box and overall size:
	var bbox = get_bounding_box(body_parts[dragged_part_type], current_rotation_step)
	var overall_size_px = bbox * CELL_SIZE

	# Instead of using the raw mouse position, calculate the drop cell (like update_highlights does):
	var drop_local = grid_parent.to_local(get_viewport().get_mouse_position())
	var drop_grid = Vector2i(int(drop_local.x / CELL_SIZE), int(drop_local.y / CELL_SIZE))
	# Then compute the ghost center exactly as you do for placing a part:
	var ghost_center = Vector2(drop_grid) * CELL_SIZE + (overall_size_px * 0.5)
	# (drag_offset can still be subtracted if needed, but for palette parts drag_offset is zero.)

	dragged_part = Sprite2D.new()
	dragged_part.texture = body_parts[dragged_part_type]["texture"]
	dragged_part.centered = true
	dragged_part.rotation = deg_to_rad(current_rotation_step * 90)
	var tex_size = dragged_part.texture.get_size()
	dragged_part.scale = Vector2(overall_size_px.x / tex_size.x, overall_size_px.y / tex_size.y)
	dragged_part.modulate = Color(1, 1, 1, 0.5)
	grid_parent.add_child(dragged_part)
	dragged_part.position = ghost_center

func toggle_visibility():
	visible = !visible

	
func _process(_delta):
	# Only update ghost & highlights if we have a valid dragged_part_type
	if dragged_part and body_parts.has(dragged_part_type):
		# Compute bounding box & size in pixels
		var bbox = get_bounding_box(body_parts[dragged_part_type], current_rotation_step)
		var overall_size_px = bbox * CELL_SIZE

		# Convert global mouse pos to grid-local coordinates
		var drop_local = grid_parent.to_local(get_global_mouse_position())
		var drop_grid = Vector2i(int(drop_local.x / CELL_SIZE), int(drop_local.y / CELL_SIZE))
		var drop_origin = Vector2(drop_grid) - drag_offset

		# Check if this is a valid drop
		var valid_drop = can_place_part(dragged_part_type, drop_origin, current_rotation_step)

		# Update ghost position
		var ghost_center = grid_parent.to_local(get_global_mouse_position()) \
			- (drag_offset * CELL_SIZE) \
			+ (overall_size_px * 0.5)
		dragged_part.position = ghost_center

		# Update highlights
		var rotated_shape = rotate_shape(body_parts[dragged_part_type]["size"], current_rotation_step)
		update_highlights(drop_origin, rotated_shape, valid_drop)
	else:
		# No drag in progress or invalid type → clear any leftover highlights
		clear_highlights()

	# Handle inventory clear hotkey
	if Input.is_action_just_pressed("ui_clear"):

		clear_inventory()

	
	if dragged_part:
		var bbox = get_bounding_box(body_parts[dragged_part_type], current_rotation_step)
		var overall_size_px = bbox * CELL_SIZE
		# Convert the global mouse position into the grid_parent's local space.
		var drop_local = grid_parent.to_local(get_global_mouse_position())
		var drop_grid = Vector2i(int(drop_local.x / CELL_SIZE), int(drop_local.y / CELL_SIZE))
		var drop_origin = Vector2(drop_grid) - drag_offset
		var valid_drop = can_place_part(dragged_part_type, drop_origin, current_rotation_step)
		
		# Update ghost position (keeping your calculation, for example)
		var ghost_center = grid_parent.to_local(get_global_mouse_position()) - (drag_offset * CELL_SIZE) + (overall_size_px * 0.5)
		dragged_part.position = ghost_center
		
		# Update highlights (your function call)
		var rotated_shape = rotate_shape(body_parts[dragged_part_type]["size"], current_rotation_step)
		update_highlights(drop_origin, rotated_shape, valid_drop)
	else:
		clear_highlights()
	if Input.is_action_just_pressed("ui_clear"):

		clear_inventory()

func _on_part_dropped(_cell_pos):
	# 1) Figure out what cell the mouse is over
	var drop_local = grid_parent.to_local(get_global_mouse_position())
	var drop_grid = Vector2i(int(drop_local.x / CELL_SIZE), int(drop_local.y / CELL_SIZE))
	var drop_origin = Vector2(drop_grid) - drag_offset

	# 2) Guard: do nothing if we don't have a real part to drop
	if dragged_part_type == "" or not body_parts.has(dragged_part_type):
		clear_highlights()
		if dragged_part:
			dragged_part.queue_free()
			dragged_part = null
		dragged_part_type = ""
		current_rotation_step = 0
		drag_offset = Vector2.ZERO
		return

	# 3) Safe to compute bounding box now
	var part_data = body_parts[dragged_part_type]
	var bbox = get_bounding_box(part_data, current_rotation_step)
	var overall_size_px = bbox * CELL_SIZE

	# 4) Place if valid
	if dragged_part and can_place_part(dragged_part_type, drop_origin, current_rotation_step):
		place_part(dragged_part_type, drop_origin, current_rotation_step)
		var primary_region = determine_primary_anchor(dragged_part_type, drop_origin, current_rotation_step)


	# 5) Always clear highlights & ghost, then reset drag state
	clear_highlights()
	if dragged_part:
		dragged_part.queue_free()
		dragged_part = null

	dragged_part_type = ""
	current_rotation_step = 0
	drag_offset = Vector2.ZERO


func populate_palette():

	var palette_container = $PaletteContainer
	# Remove existing palette buttons, if any
	for child in palette_container.get_children():
		child.queue_free()

	# Now add each palette button from body_parts
	for part_name in body_parts.keys():
		var button = preload("res://inventory/palette_button.tscn").instantiate()
		button.part_name = part_name
		button.part_texture = body_parts[part_name]["texture"]
		button.cost = body_parts[part_name]["cost"]
		palette_container.add_child(button)

func start_dragging_part(part_type: String):

	
	# This is called when a palette cell is dragged.
	dragged_part_type = part_type
	current_rotation_step = 0
	# For a new part from palette, we can use a zero drag offset.
	drag_offset = Vector2.ZERO
	redraw_dragged_part()  # This spawns a ghost of the dragged part.

# Place a body part at the given grid origin.
func place_part(part_name: String, origin, rotation_step: int = 0):

	var part_cost = body_parts[part_name]["cost"]
	
	# Attempt to charge the cost.
	if not CurrencyManager.charge(part_cost):
		print("[Inventory] Not enough DNA to place", part_name)
		return  # Abort placement!
	# -- continue with placement only if charge succeeds --
	var bbox = get_bounding_box(body_parts[part_name], rotation_step)
	var overall_size_px = bbox * CELL_SIZE
	var top_left_px = Vector2(origin) * CELL_SIZE
	var cluster_center = top_left_px + (overall_size_px * 0.5)
	

	var placed = Sprite2D.new()
	placed.texture = body_parts[part_name]["texture"]
	placed.centered = true
	placed.rotation = deg_to_rad(rotation_step * 90)
	var tex_size = placed.texture.get_size()
	placed.scale = Vector2(overall_size_px.x / tex_size.x, overall_size_px.y / tex_size.y)
	placed.position = cluster_center
	placed.set_meta("part_origin", origin)
	placed.set_meta("rotation_step", rotation_step)
	placed.set_meta("part_name", part_name)
	placed_parts_container.add_child(placed)
	

	
	# Mark grid cells as occupied.
	var rotated_shape = rotate_shape(body_parts[part_name]["size"], rotation_step)
	for y in range(rotated_shape.size()):
		for x in range(rotated_shape[y].size()):
			if rotated_shape[y][x] == 1:
				var cell = find_cell(int(origin.x + x), int(origin.y + y))
				if cell:
					cell.is_occupied = true
					cell.set_meta("part_origin", origin)
					cell.set_meta("rotation_step", rotation_step)
					cell.part_name = part_name
					
	update_equipment()  # Builds the dictionary
	GameManager.refresh_player_equipment()


func update_equipment():
	var parts_dict := {
		"head": [],
		"left_arm": [],
		"right_arm": [],
		"left_leg": [],
		"right_leg": [],
		"belly": []
	}

	for part in placed_parts_container.get_children():
		if not part.has_meta("part_origin") or not part.has_meta("rotation_step"):
			continue

		var detected_name = ""
		for bp_name in body_parts:
			if body_parts[bp_name].texture == part.texture:
				detected_name = bp_name
				break

		if detected_name == "":
			continue  # Skip unknown parts

		var origin = part.get_meta("part_origin")
		var rotation = part.get_meta("rotation_step")
		var region = determine_primary_anchor(detected_name, origin, rotation)

		var scene_path = "res://parts/%sPart.tscn" % detected_name
		var scene = load(scene_path)
		if scene:
			parts_dict[region].append(scene)

	GameManager.equipped_parts = parts_dict


func clear_part(part_name: String, origin, rotation_step: int = 0):
	# 1) Refund currency (unchanged)
	if body_parts.has(part_name):
		var cost = body_parts[part_name]["cost"]
		CurrencyManager.refund(cost)


	# 2) Immediately remove the placed part from the container
	var origin_i = Vector2i(origin)
	for part in placed_parts_container.get_children():
		if part.has_meta("part_origin") and Vector2i(part.get_meta("part_origin")) == origin_i \
		and int(part.get_meta("rotation_step")) == rotation_step \
		and part.get_meta("part_name", "") == part_name:
			placed_parts_container.remove_child(part)
			part.free()
			break

	# 3) Free up grid cells (unchanged)
	var rotated_shape = rotate_shape(body_parts[part_name]["size"], rotation_step)
	for y in range(rotated_shape.size()):
		for x in range(rotated_shape[y].size()):
			if rotated_shape[y][x] == 1:
				var cell = find_cell(origin.x + x, origin.y + y)
				if cell:
					cell.is_occupied = false
					cell.set_meta("part_origin", null)
					cell.set_meta("rotation_step", 0)
					cell.part_name = ""


func can_place_part(part_name: String, origin, rotation_step: int = 0) -> bool:
	var rotated_shape = rotate_shape(body_parts[part_name]["size"], rotation_step)
	for y in range(rotated_shape.size()):
		for x in range(rotated_shape[y].size()):
			if rotated_shape[y][x] == 1:
				var pos = Vector2i(int(origin.x + x), int(origin.y + y))
				if pos.x < 0 or pos.y < 0 or pos.y >= inventory_shape.size() or pos.x >= inventory_shape[0].size():
					return false
				var cell = find_cell(pos.x, pos.y)
				if cell == null or cell.is_occupied:
					return false
	return true

func find_cell(x: int, y: int):
	for child in grid_parent.get_children():
		if child.position == Vector2(x, y) * CELL_SIZE:
			return child
	return null

func find_empty_cell():

	for y in range(inventory_shape.size()):
		for x in range(inventory_shape[y].size()):
			if inventory_shape[y][x] == 1:
				var cell = find_cell(x, y)
				if cell and not cell.is_occupied:
					return Vector2i(x, y)
	return null

# --- Highlighting Support Functions ---

func clear_highlights():
	for cell in highlighted_cells:
		cell.modulate = Color(1, 1, 1)
	highlighted_cells.clear()

func update_highlights(drop_origin: Vector2, rotated_shape: Array, valid: bool):
	clear_highlights()
	if valid:
		for y in range(rotated_shape.size()):
			for x in range(rotated_shape[y].size()):
				if rotated_shape[y][x] == 1:
					var grid_x = int(drop_origin.x) + x
					var grid_y = int(drop_origin.y) + y
					var cell = find_cell(grid_x, grid_y)
					if cell:
						cell.modulate = Color(0.5, 1, 0.5)
						highlighted_cells.append(cell)
						

func clear_inventory():
	# 1) Snapshot all placed parts and their data:
	var parts_data := []
	for part in placed_parts_container.get_children():
		parts_data.append({
			"node": part,
			"name": part.get_meta("part_name", ""),
			"origin": Vector2i(part.get_meta("part_origin")),
			"rotation": int(part.get_meta("rotation_step", 0))
		})

	# 2) Refund currency once per part:
	for entry in parts_data:
		var name = entry["name"]
		if name != "" and body_parts.has(name):
			var cost = body_parts[name]["cost"]
			CurrencyManager.refund(cost)


	# 3) Remove all visuals immediately:
	for entry in parts_data:
		var p = entry["node"]
		placed_parts_container.remove_child(p)
		p.free()

	# 4) Reset each cell’s occupied state:
	for cell in grid_parent.get_children():
		cell.is_occupied = false
		cell.set_meta("part_origin", null)
		cell.set_meta("rotation_step", 0)
		cell.part_name = ""


	# 5) Rebuild & push to the player:
	update_equipment()
	GameManager.refresh_player_equipment()


func rect_to_points(top_left: Vector2i, bottom_right: Vector2i) -> Array:

	var points = []
	for y in range(top_left.y, bottom_right.y + 1):
		for x in range(top_left.x, bottom_right.x + 1):
			points.append(Vector2i(x, y))
	return points


func determine_primary_anchor(part_name: String, origin: Vector2, rotation_step: int) -> String:

	# Create a dictionary to store counts for each region (excluding belly)
	var counts = {
		"head": 0, "left_arm": 0, "right_arm": 0, "left_leg": 0, "right_leg": 0
	}
	# Get the rotated shape for the part
	var rotated_shape = rotate_shape(body_parts[part_name]["size"], rotation_step)
	
	for y in range(rotated_shape.size()):
		for x in range(rotated_shape[y].size()):
			if rotated_shape[y][x] == 1:
				var cell = find_cell(int(origin.x + x), int(origin.y + y))
				if cell:
					var region = cell.get_meta("region", "belly")
					# Only count non-belly regions
					if region in counts:
						counts[region] += 1
	# Find the region with the maximum count; default to "belly" if none counted.
	var primary = "belly"
	var max_count = 0
	for region_name in counts.keys():
		if counts[region_name] > max_count:
			max_count = counts[region_name]
			primary = region_name
	return primary
