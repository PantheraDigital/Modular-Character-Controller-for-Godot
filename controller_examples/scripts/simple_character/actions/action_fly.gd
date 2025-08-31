extends ActionNode

## applies a constant force moving the character

const SPEED: float = 3.0

var _movement_class: MovementState 
var _movement_manager: MovementStateManager


func _init() -> void:
	self.ACTION_ID = "MOVE" # has a duplicate ID for overriding. Dont allow duplicate IDs in ActionContainer at the same time.
	self.IS_LAYERED = true

func _ready() -> void:
	var character = get_parent().get_parent()
	_movement_class = character.find_child("FlyingMovement", false)
	if !_movement_class:
		_movement_manager = character.find_child("MovementManager", false)
		_movement_class = _movement_manager.find_child("FlyingMovement", false)


func can_play() -> bool:
	if !is_enabled:
		return false
	if _movement_manager and _movement_manager.active_state.name != "FlyingMovement":
		return false
	return true

func play(_params: Dictionary = {}) -> void:
	if _params.has("input_direction"):
		var dir: Vector3 = Vector3(_params["input_direction"].x, 0.0, _params["input_direction"].z)
		if _params["input_direction"] != Vector3.ZERO:
			dir.y = _params["aim_direction"].y
		_movement_class.move(dir, SPEED)
		super.play()

func stop() -> void:
	if _movement_class.input_vector != Vector3.ZERO:
		_movement_class.move(Vector3.ZERO, 0)
		super.stop()
