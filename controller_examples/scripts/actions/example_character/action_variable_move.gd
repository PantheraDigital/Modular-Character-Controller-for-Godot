extends ActionNode
class_name ActionGroundedMove

## Uses [MovementState] to move character along the ground \
##   relative to the direction the camera is facing. \
## Speed can be adjusted. \
## Plays animations.


@export var walk_speed: float = 3.0
@export var run_speed: float = 5.0

@export var _movement_class: MovementState 
@export var _cam_control: CamControl
@export var _anim_tree: AnimationTree

## range(0.0, 1.0) where 0 is no speed and 1.0 is full speed \
## reset to 0.5 at end of play()
var _speed_gauge: float = 0.5 


func _init() -> void:
	self.TYPE = &"MOVE"

func _process(_delta: float) -> void:
	if _anim_tree and !is_playing:
		_anim_tree.idle_to_run_scale = 0.0


func _can_play() -> bool:
	if _movement_class and _cam_control:
		if _movement_class.enabled and _movement_class.name == &"GroundedMovement":
			return true
	return false

## _params[&"input_direction"] == normalized direction to move. local space. \
## _params[&"speed_scale"] == 0.0 to 1.0 where 0.0 is no speed and 1.0 is full speed.
func _play(_params: Dictionary = {}) -> void:
	if !_params.has(&"input_direction"):
		return
	
	# remove upward movement
	var dir: Vector3 = _params[&"input_direction"]
	dir.y = 0.0
	if !dir.is_normalized():
		dir = dir.normalized()
	
	if dir.is_equal_approx(Vector3.ZERO):
		super.__exit()
		return
	
	# align movement to cam forward
	dir = dir.rotated(Vector3.UP, _cam_control.rotation.y)
	
	# get actual movement speed based on speed_scale
	var true_speed: float = 0.0
	var speed_scale: float = _params[&"speed_scale"] if _params.has(&"speed_scale") else _speed_gauge
	true_speed = lerpf(0.0, walk_speed, speed_scale * 2) \
		if speed_scale < 0.51 else \
		lerpf(0.0, run_speed, speed_scale - (1.0 - speed_scale))
	
	_movement_class.add_velocity(dir * true_speed, MovementState.Velocity_Tag.MOVE)
	
	if _anim_tree:
		_anim_tree.idle_to_run_scale = speed_scale
	
	_speed_gauge = 0.5
	super.__exit()
