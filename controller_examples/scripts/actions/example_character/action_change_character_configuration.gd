extends ActionNode

## Private action for changing character configuration.


@export var _movement_manager: MovementStateManager

var _manager: ActionManager


func _init() -> void:
	self.TYPE = &"CHANGE_CHARACTER_CONFIGURATION"


func _can_play() -> bool:
	return _manager._action_permissions and _manager._action_permissions.is_valid()

## [param _params] = {&"permission_profile":[StringName], &"movement_type":[StringName]} \
## "movement_type" - optional
func _play(_params: Dictionary = {}) -> void:
	if !_params.has(&"permission_profile"):
		return 
	
	_manager._set_active_permission_profile(_params[&"permission_profile"])
	if _movement_manager and _params.has(&"movement_type"):
		_movement_manager.set_active_state(_params[&"movement_type"])
	
	super.__exit()
