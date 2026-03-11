extends Controller

## Provides input to [ActionManager] on a character. \
## Example of a very basic ai controller.



func _process(_delta: float) -> void:
	# walk in circle by adding forward movement and a constant 5 degree horizontile rotation to direction faced. 
	_action_manager.play_action(&"MOVE", {&"input_direction":Vector3.FORWARD})
	_action_manager.play_action(&"LOOK", {&"rotation":Vector2(5.0, 0.0)})
