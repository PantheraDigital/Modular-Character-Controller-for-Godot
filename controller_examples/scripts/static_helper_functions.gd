extends Object
class_name StaticFunc

static func rotate_y_to_point(node: Node3D, point: Vector3, lerp_value: float = 0.0) -> void:
	if point == node.position or point.is_equal_approx(Vector3.ZERO):
		return
	if !is_equal_approx(lerp_value, 0.0):
		point = -point
		node.rotation.y = lerp_angle(node.rotation.y, atan2(point.x, point.z), lerp_value)
	else:
		node.transform = node.transform.looking_at(Vector3(point.x, node.position.y, point.z))
