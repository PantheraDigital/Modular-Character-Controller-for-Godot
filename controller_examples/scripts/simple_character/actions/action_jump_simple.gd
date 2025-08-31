extends ActionNode


const JUMP_STRENGTH: float = 5.0

var _movement_class: MovementState 
var _movement_manager: MovementStateManager

@onready var _character: CharacterBody3D = $"../.."


func _init() -> void:
	self.ACTION_ID = "JUMP"

func _ready() -> void:
	_movement_class = _character.find_child("GroundedMovement", false)
	if !_movement_class:
		_movement_manager = _character.find_child("MovementManager", false)
		_movement_class = _movement_manager.find_child("GroundedMovement", false)


func can_play() -> bool:
	if !is_enabled:
		return false
	if _movement_manager and _movement_manager.active_state.name != "GroundedMovement":
		return false
	return _character.is_on_floor() and is_playing == false

func play(_params: Dictionary = {}) -> void:
	_movement_class.add_impulse(Vector3.UP, JUMP_STRENGTH)
	super.play()
	# actions must not enter and exit in the same frame
	await get_tree().process_frame # delay prevents inf loop within controller and action container
	super.stop()
