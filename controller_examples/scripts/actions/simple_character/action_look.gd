extends ActionNode

## Rotates the camera on the character.


## The speed rotation should happen at. 0.0, no rotation. 0.1, slow. 1.0, instant.
@export_range(0.0, 1.0) var lerp_value: float = 0.15
@export var face_velocity: Array[Node3D]
@export var face_cam_forward: Array[Node3D]

@export var _cam_control: CamControl

var _character: CharacterBody3D


func _init() -> void:
	self.TYPE = &"LOOK"

func _process(_delta: float) -> void:
	if face_velocity:
		for node: Node3D in face_velocity:
			StaticHelpers.face_point(node, _character.velocity, false, lerp_value)
	if face_cam_forward:
		for node: Node3D in face_cam_forward:
			StaticHelpers.face_point(node, -_cam_control.basis.z, false, lerp_value)


## [param _params] = {&"rotation": Vector2} \
## rotation is the amount to rotate and the direction. \
## Vector2(5,90): 5 deg right, 90 deg up
func _play(_params: Dictionary = {}) -> void:
	if !_params.has(&"rotation"):
		return
	
	_cam_control.rotate_xy(_params[&"rotation"])
	super.__exit()
