extends Node
class_name TorsoData

static func rect_to_points(top_left: Vector2i, bottom_right: Vector2i) -> Array:
	var points = []
	for y in range(top_left.y, bottom_right.y + 1):
		for x in range(top_left.x, bottom_right.x + 1):
			points.append(Vector2i(x, y))
	return points

static var anchors = {
	"head": rect_to_points(Vector2i(4, 0), Vector2i(7, 2)), #+  (remove comma at end of this line for "+" to work)
			#rect_to_points(Vector2i(8, 0), Vector2i(8, 0)),  # Combining two regions.
	"left_arm": rect_to_points(Vector2i(0, 4), Vector2i(3, 6)),
	"right_arm": rect_to_points(Vector2i(8, 3), Vector2i(10, 6)),
	"left_leg": rect_to_points(Vector2i(2, 8), Vector2i(4, 10)),
	"right_leg": rect_to_points(Vector2i(6, 8), Vector2i(9, 10)),
	"belly": rect_to_points(Vector2i(5, 4), Vector2i(5, 5))
}
