extends CharacterBody2D

var powers: Array = []
var max_jumps: int = 1
var jump_count: int = 0
var base_jump_velocity: float
var is_facing_right := true

var dynamic_parts: Array = []

@export var speed := 120.0
@export var jump_velocity := -300.0
@export var gravity := 800.0


# Dictionary to track attached body parts
@onready var parts_container = $PartsContainer

@onready var equipped_parts = {
	"head": $PartsContainer/HeadAnchor,
	"left_arm": $PartsContainer/LeftArmAnchor,
	"right_arm": $PartsContainer/RightArmAnchor,
	"left_leg": $PartsContainer/LeftLegAnchor,
	"right_leg": $PartsContainer/RightLegAnchor,
	"belly":$PartsContainer/BellyAnchor
}


func _ready():
	base_jump_velocity = jump_velocity
	load_parts_from_data(GameManager.equipped_parts)

		
		
func _physics_process(delta: float) -> void:
	# Horizontal movement (unchanged)
	var input_dir = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	for part in dynamic_parts:
		if part.has_method("set_move_direction"):
			part.set_move_direction(sign(velocity.x))
	velocity.x = input_dir * speed

	# Gravity
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		# Reset jump_count whenever we hit the ground
		jump_count = 0

	# Jumping (now respects max_jumps instead of only floor-jumps)
	if Input.is_action_just_pressed("ui_accept") and jump_count < max_jumps:
		velocity.y = jump_velocity
		jump_count += 1

	move_and_slide()
	if input_dir != 0:
		is_facing_right = input_dir > 0
		parts_container.scale.x = 1 if is_facing_right else -1
	queue_redraw()  # Ensures _draw() updates every frame


func clear_parts():
	# remove all visuals
	for anchor in equipped_parts.values():
		for child in anchor.get_children():
			child.queue_free()
	dynamic_parts.clear()

	# reset powers & jump state
	powers.clear()
	jump_velocity = base_jump_velocity
	max_jumps = 1
	jump_count = 0

func apply_part_power(power):

	match power.id:
		"double_jump":
			max_jumps = 2
			print("Double Jump equipped! max_jumps =", max_jumps)
		"high_jump":
			# (keep if you still want height boost on another leg)
			jump_velocity = base_jump_velocity * 1.5
		_:
			# future power IDs here…
			pass

func _input(event):
	if event.is_action_pressed("attack_b"):
		if Input.is_key_pressed(KEY_SHIFT):
			PowerManager.trigger_attack_group("attack_b_shift")
		else:
			PowerManager.trigger_attack_group("b")
	elif event.is_action_pressed("attack_a"):
		if Input.is_key_pressed(KEY_SHIFT):
			PowerManager.trigger_attack_group("attack_a_shift")
		else:
			PowerManager.trigger_attack_group("a")


	
#
#
#func trigger_powers_for_slot(slot: String):
	#for power in powers:
		#if power is Power and power.input_slot == slot:
			#execute_power(power)
#


func get_part_type_from_node(node: Node) -> String:
	if node.name.contains("Eyeball"):
		return "Eyeball"
	elif node.name.contains("Tentacle"):
		return "Tentacle"
	elif node.name.contains("RobotArm"):
		return "RobotArm"
	elif node.name.contains("Horn"):
		return "Horn"
	else:
		return "Unknown"

func apply_layout(children: Array, layout_type: String, total_width: float = 140.0) -> void:
	if children.is_empty():
		return

	var part_width := 16.0  # Adjust dynamically if needed

	match layout_type:
		"fan":
			for i in range(children.size()):
				var c := children[i] as Node2D
				var offset := i - float(children.size() - 1) / 2.0
				c.position = Vector2.ZERO
				c.rotation = deg_to_rad(offset * 15.0)

		"combo":
			for i in range(children.size()):
				var c := children[i] as Node2D
				var offset := i - float(children.size() - 1) / 2.0
				c.position = Vector2(offset * 10.0, 0)
				c.rotation = deg_to_rad(offset * 5.0)

		"line", _:
			var spacing := (total_width - children.size() * part_width) / (children.size() + 1)
			var x := -total_width / 2.0 + spacing + part_width / 2.0
			for i in range(children.size()):
				var c := children[i] as Node2D
				c.position = Vector2(x, 0)
				c.rotation = 0
				x += part_width + spacing

func attach_part(part_scene, slot) -> Node:
	if not equipped_parts.has(slot):
		return null

	var anchor_node = equipped_parts[slot]

	# Instantiate your part
	var inst = part_scene.instantiate()
	anchor_node.add_child(inst)

	# 1) Always register the instance so rebuild_powers can see it
	dynamic_parts.append(inst)

	# 2) But only call move_direction on parts that support it
	if inst.has_method("set_move_direction"):
		inst.set_move_direction(sign(velocity.x))  # or leave it blank until next _physics_process

	return inst

func load_parts_from_data(part_dict: Dictionary) -> void:
	clear_parts()

	# 1) Attach all parts (this populates dynamic_parts[])
	for slot in part_dict.keys():
		for scene in part_dict[slot]:
			var inst = attach_part(scene, slot)
			# no apply_part_power here!

	# 2) Once every part is attached, rebuild the entire power list
	rebuild_powers()
	

func execute_power(power: Power):
	match power.id:
		"tentacle_whip":
			print("🌀 Tentacle Whip activated!")
			tentacle_whip()
		_:
			print("Power activated: ", power.id)


func rebuild_powers() -> void:
	# Reset base state
	powers.clear()
	max_jumps = 1
	jump_velocity = base_jump_velocity
	# Walk every dynamically attached part
	for inst in dynamic_parts:
		# Only PartData nodes carry a `.powers` array
		if inst is PartData:
			for power in inst.powers:
				if power is Power and not powers.has(power):
					powers.append(power)
					apply_part_power(power)



func get_symmetric_offsets(count: int, full_span: float) -> Array:
	# full_span is total width (e.g. 20 → from -10 to +10)
	var half_span = full_span * 0.5

	# 1) Build the raw evenly-spaced line
	var raw := []
	if count == 1:
		raw = [0.0]
	else:
		var step = full_span / (count - 1)
		for i in range(count):
			raw.append(-half_span + step * i)

	# 2) Re-order: center outwards
	var ordered := []
	if count % 2 == 1:
		# odd: start with center
		var center_idx = count / 2
		ordered.append(raw[center_idx])
		for i in range(1, center_idx + 1):
			ordered.append(raw[center_idx - i])            # left of center
			if center_idx + i < raw.size():
				ordered.append(raw[center_idx + i])        # right of center
	else:
		# even: alternate outermost pairs
		for i in range(count / 2):
			ordered.append(raw[i])                         # left edge, then next
			ordered.append(raw[count - 1 - i])             # right edge, then next

	# 3) Sort ascending so children appear left→right
	ordered.sort()
	return ordered

func get_part_layout(part_type: String) -> String:
	match part_type:
		"eyeball", "nose": return "line"
		"tentacle", "robotarm": return "fan"
		"horn", "head": return "combo"
		_: return "line"


func arrange_anchor_parts(anchor: Node2D, part_type: String) -> void:
	var raw_children := anchor.get_children()
	var children: Array = []

	for n in raw_children:
		var c := n as Node2D
		if c != null:
			children.append(c)

	var count: int = children.size()
	if count == 0:
		print("No children found for anchor: ", anchor.name)
		return

	var layout: String = get_part_layout(part_type)

	if layout == "fan":
		for i in range(count):
			var c: Node2D = children[i]
			var offset := i - float(count - 1) / 2.0
			c.position = Vector2.ZERO
			c.rotation = deg_to_rad(offset * 15.0)
		return

	# Layout variables
	var total_width: float = 140.0  # adjust as needed
	var part_width: float = 16.0
	var spacing: float = (total_width - (count * part_width)) / float(count + 1)

	var x := -total_width / 2.0 + spacing + part_width / 2.0

	print("----- Layout Debug for ", anchor.name, " -----")
	for i in range(count):
		var c: Node2D = children[i]
		print("  → Child[", i, "] ", c.name, ": placing at x=", x, ", spacing=", spacing)
		print("HeadAnchor.global_position =", anchor.global_position)
		print("HeadAnchor.position =", anchor.position)

		c.position = Vector2(x, 0)
		if layout == "combo":
			var center_offset := i - float(count - 1) / 1
			c.rotation = deg_to_rad(center_offset * 5.0)
		else:
			c.rotation = 0
		x += (part_width + spacing)/1.5 


func get_linear_offsets(count: int, full_span: float) -> Array:
	if count <= 1:
		return [0.0]    # single eye goes dead-center
	var half_span: float = full_span * 0.5
	var offsets: Array = []
	for i in range(count):
		var t: float = float(i) / float(count - 1)
		offsets.append( lerp(-half_span, half_span, t) )
	return offsets


func get_active_tentacles() -> Array:
	var tentacles := []
	for part in dynamic_parts:
		if part.name.contains("Tentacle"):  # tweak to match your naming
			tentacles.append(part)
	return tentacles
func tentacle_whip():
	var tentacles = get_active_tentacles()
	if tentacles.is_empty():
		print("No tentacle parts available!")
		return

	for t in tentacles:
		var angle = t.global_position.angle_to_point(get_global_mouse_position())


		var tween = create_tween()
		tween.tween_property(t, "rotation", angle, 0.15).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

		# Stretch outward (scale up, snap)
		var original_scale = t.scale
		var stretched = original_scale * Vector2(3, 0.8)

		tween.tween_property(t, "scale", stretched, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_interval(0.05)
		tween.tween_property(t, "scale", original_scale, 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		#tween.tween_property(t, "rotation", angle + deg2rad(90), 0.15) \ 
		#.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		# Reset rotation slowly
		tween.tween_property(t, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _draw():
	var from = Vector2.ZERO  # Local center of the tentacle node
	var to = get_global_mouse_position() - global_position
	draw_line(from, to, Color.CYAN, 2)
