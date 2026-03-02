extends Node3D
class_name CamControl

## Provides functions for moving a camera attached to a character for 
##   first person or third person perspective.
##
## Expected Scene Tree:
## FP_Character
## |-CamPivot (CamControl)
## | |-Camera3D
##
## or
## 
## TP_Character
## |-CamPivot (CamControl)
## | |-SpringArm3D (TopLevel: true)
## | | |-Camera3D


@export_group("Camera")
@export var sensitivity_x : float = 0.005
@export var sensitivity_y : float = 0.005
@export var clamp_vertical_rotation : bool = true

@export_group("Spring Arm")
## Extends spring arm length to camera location on _ready
@export var auto_set_len: bool = false
@export var vertical_smoothing: float = 0.0
@export var horizontal_smoothing: float = 0.0

var camera: Camera3D
var spring_arm: SpringArm3D



func _ready() -> void:
	camera = find_child("Camera3D")
	spring_arm = find_child("SpringArm3D")
	
	if !spring_arm:
		return
	
	# prevent spring arm from colliding with owning character
	spring_arm.add_excluded_object(get_parent().get_rid()) 
	
	if auto_set_len:
		spring_arm.spring_length = spring_arm.global_position.distance_to(camera.global_position)
	
	if !is_zero_approx(vertical_smoothing) or !is_zero_approx(horizontal_smoothing):
		spring_arm.top_level = true

func _process(_delta: float) -> void:
	if spring_arm and spring_arm.top_level:
		spring_arm.rotation = rotation

func _physics_process(_delta: float) -> void:
	if spring_arm and spring_arm.top_level:
		_smooth_move()


## vec is the amount to rotate and the direction. \
## Vector2(5,90): 5 deg right, 90 deg up
func rotate_xy(vec: Vector2) -> void:
	rotation.x -= vec.y * sensitivity_y
	if clamp_vertical_rotation:
		rotation.x = clampf(rotation.x, deg_to_rad(-89.9), deg_to_rad(45.0))
	rotation.y += -vec.x * sensitivity_x
	
	transform = transform.orthonormalized()

func face_point(point: Vector3, _use_pitch: bool = false, _lerp_val: float = 1.0) -> void:
	var target_point: Vector3 = point if _use_pitch else Vector3(point.x, 0.0, point.z)
	if target_point.is_equal_approx(Vector3.ZERO):
		return
	var target_quat: Quaternion = Quaternion(Vector3.FORWARD, target_point).normalized()
	
	_lerp_val = clampf(_lerp_val, 0.0, 1.0)
	quaternion = target_quat if is_equal_approx(_lerp_val, 1.0) else \
				quaternion.slerp(target_quat, _lerp_val)

func detach_cam_from_spring_arm(cam_pivot_offset: Vector3 = Vector3.ZERO) -> void:
	if camera.get_parent() == self:
		return
	
	camera.reparent(self,false)
	camera.position = cam_pivot_offset

func attach_cam_to_spring_arm() -> void:
	if !spring_arm or (spring_arm and camera.get_parent() == spring_arm):
		return
	
	camera.reparent(spring_arm,false)

func is_first_person() -> bool:
	return camera.get_parent() == self

func to_first_person() -> void:
	if is_first_person():
		return
		
	detach_cam_from_spring_arm()
	#camera.set_cull_mask_value(2, true)

func to_third_person() -> void:
	if !is_first_person() or !spring_arm:
		return
		
	attach_cam_to_spring_arm()
	#camera.set_cull_mask_value(2, false)


func _smooth_move() -> void:
	if !is_zero_approx(vertical_smoothing):
		spring_arm.global_position.y = lerpf(spring_arm.global_position.y, global_position.y, vertical_smoothing)
	else:
		spring_arm.global_position.y = global_position.y
	
	if !is_zero_approx(horizontal_smoothing):
		spring_arm.global_position.x = lerpf(spring_arm.global_position.x, global_position.x, horizontal_smoothing)
		spring_arm.global_position.z = lerpf(spring_arm.global_position.z, global_position.z, horizontal_smoothing)
	else:
		spring_arm.global_position.x = global_position.x
		spring_arm.global_position.z = global_position.z
