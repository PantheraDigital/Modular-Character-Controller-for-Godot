extends Object
class_name CharacterStep3D

## Created by: Panthera
## https://github.com/PantheraDigital
##
## Purpose:
## This static class helps CharacterBody3D objects ascend and descend ledges such as stairs.
## 
## Usage:
## Be sure to utilize these methods within the CharacterBody3D’s _physics_process()
## and to limit step_down and step_up calls when possible. For example they don't need 
## to be called if not moving. step_down does not need to be called unless the CharacterBody3D is falling.
## step_up does not need to be called unless there is a wall/unwalkable surface infront of CharacterBody3D.

# Inspired by Godot: Stair-stepping Demo addon
# https://github.com/kelpysama/Godot-Stair-Step-Demo/tree/main
#
# It did not quite work for me for my third person controller so I built my own, 
# taking some techniques from it, but remaking it to work as a static class so it can 
# easily be added to any character scripts.


## Project the CharacterBody3D down to find suitable ground to “step down” to. (Similar to apply_floor_snap())
## Place AFTER CharacterBody3D.move_and_slide()
##
## Use direction and distance to perform extra forward checks if directly down is not a suitable step.
## The ground_validation Callable gets given the point and normal of the projection down and is called before returning results. Use this to filter valid step down locations.
## EX: func(_point : Vector3, _normal : Vector3) -> bool : return _normal.angle_to(Vector3.UP) <= floor_max_angle
##	This will prevent returning points that have a slope too steep to walk on.
##
## Returns a Dictionary of the position and normal that may be stepped down to
static func step_down(rid : RID, transform : Transform3D, max_step_height : float, direction : Vector3 = Vector3.ZERO, distance : float = 0.0, ground_validation : Callable = func(_point : Vector3, _normal : Vector3) -> bool : return true) -> Dictionary:
	const BAD_POSITION = {}
	var body_test_result = PhysicsTestMotionResult3D.new()
	var body_test_params = PhysicsTestMotionParameters3D.new()
	
	body_test_params.from = transform
	body_test_params.motion = Vector3(0, -max_step_height, 0)
	
	if direction.is_zero_approx() or is_equal_approx(distance, 0.0):
		if PhysicsServer3D.body_test_motion(rid, body_test_params, body_test_result):
			return {"point": body_test_result.get_collision_point(), "normal": body_test_result.get_collision_normal()}
		else:
			return BAD_POSITION
	
	var dir_normalized : Vector3 = direction if direction.is_normalized() else direction.normalized()
	var mid_point_offset : Vector3 = dir_normalized * (distance * 0.5)
	var end_point_offset : Vector3 = dir_normalized * distance
	
	# test start point
	if PhysicsServer3D.body_test_motion(rid, body_test_params, body_test_result):
		if ground_validation.call(body_test_result.get_collision_point(), body_test_result.get_collision_normal()):
			return {"point": body_test_result.get_collision_point(), "normal": body_test_result.get_collision_normal()}
	
	# test mid point
	body_test_params.from.origin = transform.origin + mid_point_offset
	if PhysicsServer3D.body_test_motion(rid, body_test_params, body_test_result):
		if ground_validation.call(body_test_result.get_collision_point(), body_test_result.get_collision_normal()):
			return {"point": body_test_result.get_collision_point(), "normal": body_test_result.get_collision_normal()}
	
	# test end point
	body_test_params.from.origin = transform.origin + end_point_offset
	if PhysicsServer3D.body_test_motion(rid, body_test_params, body_test_result):
		if ground_validation.call(body_test_result.get_collision_point(), body_test_result.get_collision_normal()):
			return {"point": body_test_result.get_collision_point(), "normal": body_test_result.get_collision_normal()}
	
	return BAD_POSITION # not stepping down

## Project the CharacterBody3D up and over a ledge to find suitable ground to “step up” to.
## Place BEFORE CharacterBody3D.move_and_slide()
##
## Use minimum_ledge_depth to prevent stepping up onto ledges that are too small. Keep at 0.0 to step up onto any ledge.
## 
## Returns a Dictionary of the ledge position and ledge normal
static func step_up(rid : RID, transform : Transform3D, max_step_height : float, direction : Vector3, distance : float, minimum_ledge_depth : float = 0.0) -> Dictionary:
	const BAD_POSITION = {}
	if direction.is_zero_approx():
		return BAD_POSITION
	
	var body_test_result = PhysicsTestMotionResult3D.new()
	var body_test_params = PhysicsTestMotionParameters3D.new()
	var dir_normalized : Vector3 = direction if direction.is_normalized() else direction.normalized()
	
	body_test_params.from = transform
	body_test_params.motion = dir_normalized * distance
	
	
	# project forward #
	if !PhysicsServer3D.body_test_motion(rid, body_test_params, body_test_result):
		return BAD_POSITION
	
	var remaining_forward_vector : Vector3 = body_test_result.get_remainder()
	body_test_params.from = body_test_params.from.translated(body_test_result.get_travel())
	
	# project up #
	body_test_params.motion = Vector3(0, max_step_height, 0)
	PhysicsServer3D.body_test_motion(rid, body_test_params, body_test_result)
	body_test_params.from = body_test_params.from.translated(body_test_result.get_travel())
	
	# project forward remaining forward dist #
	body_test_params.motion = remaining_forward_vector
	if PhysicsServer3D.body_test_motion(rid, body_test_params, body_test_result):
		if body_test_result.get_travel().length() < minimum_ledge_depth:
			return BAD_POSITION
	body_test_params.from = body_test_params.from.translated(body_test_result.get_travel())
	
	# project down #
	body_test_params.motion = Vector3(0, -max_step_height, 0)
	if !PhysicsServer3D.body_test_motion(rid, body_test_params, body_test_result):
		return BAD_POSITION
	# the returned position is at the height of the step and the distance of the first projection forward (aka the step ledge)
	return {"point": body_test_result.get_collision_point(), "normal": body_test_result.get_collision_normal()}


## Snap intersect ray to the ground below origin, making it parallel to the ground.
## Will not raycast if ground is not found, unless allways_cast is set true.
## Will exclude RIDs passed into exclude array. Use CollisionObject3D.get_rid() to get the RID associated with a CollisionObject3D-derived node.
##
## Returns the results of the intersect_ray parallel to the ground or empty Dictionary if no collision.
## Returns {"error":"message"} if allways_cast is false and ray could not be aligned to ground.
static func snapped_intersect_ray(space_state : PhysicsDirectSpaceState3D, origin : Vector3, direction : Vector3, length : float, allways_cast : bool = false, exclude : Array = [], stabilizer_width : float = 0.01, stabilizer_height : float = 0.3) -> Dictionary:
	# visualization of rays
	#  A__B
	#  |\ |
	#  | \|
	#  X__C___x
	#  |
	#  |
	#  Y
	#
	# X = origin
	# A = stabilizer origin
	#
	# X->A->B->C = stabilizer
	#
	# X->Y = floor normal ray (stabilizer_height + (stabilizer_height/2))
	# B->C = front stabalizer ray (stabilizer_height + VERTICAL_EXTENSION + slope_adjustment)
	# A->X = back stabalizer ray (stabilizer_height + VERTICAL_EXTENSION + slope_adjustment)
	# X->x = floor aligned raytrace (length)
	#
	# X->A = (stabilizer_height)
	# A->B = (stabilizer_width)
	const VERTICAL_EXTENSION : float = 0.2
	var query : PhysicsRayQueryParameters3D = null
	
	query = PhysicsRayQueryParameters3D.create(Vector3(origin.x, origin.y + (stabilizer_height * 0.5), origin.z), Vector3(origin.x, origin.y - stabilizer_height, origin.z))
	query.exclude = exclude
	var init_result : Dictionary = space_state.intersect_ray(query)
	if !init_result: # no ground
		if allways_cast:
			#DebugDraw3D.draw_ray(origin, ((origin + (direction * length)) - origin).normalized(), length, Color.AQUA)
			query = PhysicsRayQueryParameters3D.create(origin, origin + (direction * length))
			query.exclude = exclude
			return space_state.intersect_ray(query)
		else:
			return {"error":"no ground"}
	
	var floor_normal : Vector3 = init_result.normal
	var floor_angle : float = Vector3.UP.angle_to(floor_normal) if Vector3.UP.angle_to(floor_normal) < deg_to_rad(90.0) else deg_to_rad(89.9) # clamp floor angle
	
	if !direction.is_normalized():
		direction = direction.normalized()
	
	# front stabilizer ray
	var A : Vector3 = Vector3(origin.x, origin.y + stabilizer_height, origin.z)
	var B : Vector3 = A + (direction * stabilizer_width)
	var slope_adjustment : float = (A.distance_to(B) * tan(floor_angle)) # doesn't work with 90 deg or greater
	var height : float = stabilizer_height + slope_adjustment + VERTICAL_EXTENSION
	var C : Vector3 = Vector3(B.x, B.y - height, B.z)
	#DebugDraw3D.draw_line(B, C)
	query = PhysicsRayQueryParameters3D.create(B,C, 0xFFFFFFFF, exclude)
	var front_result : Dictionary = space_state.intersect_ray(query)
	
	# back stabilizer ray
	var X : Vector3 = Vector3(A.x, A.y - height, A.z)
	#DebugDraw3D.draw_line(A, X)
	query = PhysicsRayQueryParameters3D.create(A,X, 0xFFFFFFFF, exclude)
	var back_result : Dictionary = space_state.intersect_ray(query)
	
	# floor aligned ray
	var dir : Vector3 = origin + (direction * length)
	var start : Vector3 = origin
	if front_result and back_result:
		dir = (front_result.position - back_result.position).normalized()
		start = back_result.position
		start.y += 0.001 # small height adjustment to keep ray out of ground
	elif !allways_cast:
		return {"error":"stabilizer leg fail"} # trouble aligning 
	
	#DebugDraw3D.draw_ray(start, ((start + (dir * length)) - start).normalized(), length, Color.AQUA)
	query = PhysicsRayQueryParameters3D.create(start, start + (dir * length), 0xFFFFFFFF, exclude)
	return space_state.intersect_ray(query)
