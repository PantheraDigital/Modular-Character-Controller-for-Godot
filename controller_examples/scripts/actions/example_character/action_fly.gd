extends ActionNode

## Uses [MovementState] to move character in any direction, including up and down
## relative to the direction the camera is facing.


const SPEED: float = 3.0

@export var _movement_class: MovementState 
@export var _cam_control: CamControl


func _init() -> void:
	self.TYPE = &"MOVE"


func _can_play() -> bool:
	if _movement_class and _cam_control:
		if _movement_class.enabled and _movement_class.name == &"FlyingMovement":
			return true
	return false

## [param _params] = {&"input_direction":[Vector3], &"alt_move":[bool]} \
## "alt_move" - optional, sets if velocity is applied as direct movement or indirect. (use to apply two movements at the same time)
func _play(_params: Dictionary = {}) -> void:
	if !_params.has(&"input_direction"):
		return 
	
	var dir: Vector3 = _params[&"input_direction"]
	if dir != Vector3.ZERO and !dir.is_equal_approx(Vector3.UP) and !dir.is_equal_approx(Vector3.DOWN):
		dir.y = (-_cam_control.camera.global_basis.z).y
	
	# align movement to cam forward
	dir = dir.rotated(Vector3.UP, _cam_control.rotation.y)
	
	if !_params.has(&"alt_move"):
		_movement_class.add_velocity(dir * SPEED, MovementState.Velocity_Tag.MOVE)
	else:
		_movement_class.add_velocity( dir * SPEED, (MovementState.Velocity_Tag.ALT_MOVE if _params[&"alt_move"] else MovementState.Velocity_Tag.MOVE) )
	
	super.__exit()
