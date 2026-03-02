extends ActionNode

## Increases the movement speed of MOVE action when it plays.


var _manager: ActionManager

var _move_action: ActionGroundedMove


func _init() -> void:
	self.TYPE = &"RUN"

func _ready() -> void:
	_move_action = _manager._action_container.get_actions_by_type(&"MOVE", func(action:ActionNode): return action is ActionGroundedMove)[0]


func _can_play() -> bool:
	return _move_action != null

func _enter() -> void:
	_move_action.play_action.connect(_speed_boost)

func _exit() -> void:
	_move_action.play_action.disconnect(_speed_boost)


# Connected to play_action signal so that speed is only changed when the move action plays
#  rather than hard setting a variable in move action.
# _speed_gauge is reset to a default value every _process in move action.
func _speed_boost(action: ActionNode) -> void:
	if action == _move_action:
		_move_action._speed_gauge = 1.0
