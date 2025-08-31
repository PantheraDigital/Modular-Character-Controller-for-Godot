extends Node3D


@export_group("CAM")
@export var sensitivity_x : float = 0.005
@export var sensitivity_y : float = 0.005
@export var normal_fov : float = 75.0
@export var run_fov : float = 90.0

enum FOV {NORMAL, RUN}
const CAMERA_BLEND : float = 0.05

@onready var camera : Camera3D = $Camera3D


func change_fov(setting: FOV) -> void:
	match setting:
		FOV.NORMAL:
			camera.fov = lerp(camera.fov, normal_fov, CAMERA_BLEND)
		FOV.RUN:
			camera.fov = lerp(camera.fov, run_fov, CAMERA_BLEND)

func rotate_view(vec: Vector2) -> void:
	rotation.x -= vec.y * sensitivity_y
	rotation.x = clampf(rotation.x, -PI/4, PI/4)
	rotation.y += -vec.x * sensitivity_x

func set_direction(vec: Vector2) -> void:
	transform = transform.looking_at(Vector3(vec.x, position.y, vec.y))

func get_cam_forward() -> Vector3:
	return -camera.get_global_transform().basis.z 
