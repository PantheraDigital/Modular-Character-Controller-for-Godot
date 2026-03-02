extends Object
class_name StaticHelpers

## Static functions 


## Rotates node to look at point.
##
## [param _use_pitch]: If false, rotation will only happen on the Y axis. If true, rotation will happen on all axis.
## [param _lerp_val]: The speed rotation should happen at. 0.0, no rotation. 0.1, slow. 1.0, instant.
static func face_point(node: Node3D, point: Vector3, _use_pitch: bool = false, _lerp_val: float = 0.0) -> void:
	if point.is_equal_approx(node.position) or point.is_equal_approx(Vector3.ZERO) or point.is_equal_approx(Vector3.UP):
		return
	
	_lerp_val = clampf(_lerp_val, 0.0, 1.0)
	var target: Vector3 = point if _use_pitch else Vector3(point.x, node.position.y, point.z)
	if target.is_equal_approx(node.transform.origin):
		return
	
	if is_equal_approx(_lerp_val, 1.0):
		node.transform = node.transform.looking_at(target)
	else:
		var target_transform: Transform3D = node.transform.looking_at(target)
		node.transform = node.transform.interpolate_with(target_transform, _lerp_val)
