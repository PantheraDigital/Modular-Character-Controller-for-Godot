extends ActionNode

## Sends character up by applying upward force.
## If called twice in quick succession, 
##   will swap character configuration between "flying" and "grounded".


const JUMP_STRENGTH: float = 5.0

@export var _double_tap_window_msec: int = 500
@export var _movement_class: MovementState
@export var _anim_tree: AnimationTree

var _character: CharacterBody3D
var _manager: ActionManager

var _config_change_action: ActionNode
var _last_call_timestamp: int = -1


func _init() -> void:
	self.TYPE = &"JUMP"

func _process(_delta: float) -> void:
	if _anim_tree and Time.get_ticks_msec() - _last_call_timestamp > 5:
		_anim_tree.jump = false


func _can_play() -> bool:
	if _movement_class:
		return is_playing == false
	return false

func _enter() -> void:
	_config_change_action = _manager._get_action(&"CHANGE_CHARACTER_CONFIGURATION", ActionManager.GetFilterType.PRIVATE_ACTIONS)

func _play(_params: Dictionary = {}) -> void:
	# jump if out of the double tap window, change character config if in the double tap window
	if Time.get_ticks_msec() - _last_call_timestamp > _double_tap_window_msec:
		if _character.is_on_floor() and _manager._active_permission_profile == &"grounded":
			_movement_class.add_velocity(Vector3.UP * JUMP_STRENGTH, MovementState.Velocity_Tag.JUMP)
			if _anim_tree:
				_anim_tree.jump = true
	else:
		# trigger CHANGE_CHARACTER_CONFIGURATION
		# Method 1 - use action directly to change configuration
		if _config_change_action:
			if _manager._active_permission_profile == &"grounded":
				_config_change_action.play({&"permission_profile":&"flying", &"movement_type":&"FlyingMovement"})
			else:
				_config_change_action.play({&"permission_profile":&"grounded", &"movement_type":&"GroundedMovement"})
		# Method 2 - request action through manager. does not need to save ref to Action Node
		#if _manager._active_permission_profile == &"grounded":
			#_manager._play_private_action(&"CHANGE_CHARACTER_CONFIGURATION", {&"permission_profile":&"flying", &"movement_type":&"FlyingMovement"})
		#else:
			#_manager._play_private_action(&"CHANGE_CHARACTER_CONFIGURATION", {&"permission_profile":&"grounded", &"movement_type":&"GroundedMovement"})
	
	_last_call_timestamp = Time.get_ticks_msec()
	super.__exit()
