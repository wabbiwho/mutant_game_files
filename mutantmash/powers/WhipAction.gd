# res://powers/WhipAction.gd
class_name WhipAction
extends AttackAction

@export var rotation_offset_deg := 90

func start(actor: Node) -> void:
	var mouse_pos = actor.get_viewport().get_mouse_position()
	var angle = actor.global_position.angle_to_point(mouse_pos)
	angle += deg_to_rad(rotation_offset_deg)

	var tween = actor.create_tween()

	tween.tween_property(actor, "rotation", angle, 0.15)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var original_scale = actor.scale
	var stretched = original_scale * Vector2(1.2, 0.8)

	tween.tween_property(actor, "scale", stretched, 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.05)
	tween.tween_property(actor, "scale", original_scale, 0.1).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	tween.tween_property(actor, "rotation", 0.0, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
