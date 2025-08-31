extends Controller

## provides input to ActionContainer
## example of player controller

const DOUBLE_TAP_DELAY: float = 0.25

var _cam_pivot: Node3D
var _action_container: ActionContainer

var _last_input_window: float = 0.0
var _last_input: StringName
var _input_tracking: Dictionary[StringName, Variant] = \
{
	"move":Vector3.ZERO,
	"run":false, 
	"jump":false, 
	"slide":false,
}


func _on_controlled_obj_change():
	if _action_container and _action_container.action_exit.is_connected(_on_action_exit):
		_action_container.action_exit.disconnect(_on_action_exit)
	
	_cam_pivot = controlled_obj.get_node("CamPivot")
	if _cam_pivot.camera:
		_cam_pivot.camera.make_current()
	
	_action_container = controlled_obj.get_node("ActionContainer")
	_action_container.action_exit.connect(_on_action_exit) # needed to prevent missed inputs
		# warning: can cause inf loop
		# evaluate_all_input -> stop_action -> action_exit -> evaluate_all_input
		# actions must not enter and exit in the same frame


func _process(delta: float) -> void:
	if _last_input_window > 0.0:
		_last_input_window -= delta
		if _last_input_window <= 0.0:
			_last_input = ""
	
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards").rotated(-_cam_pivot.rotation.y)
	_input_tracking["move"] = Vector3(input.x, 0.0, input.y)
	evaluate_input("move")

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	
	if event is InputEventMouseMotion:
		_cam_pivot.rotate_view(event.relative)
	
	for check in ["run", "jump", "dash"]:
		if event.is_action(check):
			var is_double: bool = false
			_input_tracking[check] = event.is_action_pressed(check)
			if event.is_action_pressed(check):
				if _last_input == "":
					_last_input = check
					_last_input_window = DOUBLE_TAP_DELAY
				elif _last_input == check:
					is_double = true
					_last_input = ""
					_last_input_window = 0.0
			evaluate_input(check, is_double)


func evaluate_input(key: String, double_tap: bool = false) -> void:
	match key:
		"move":
			_action_container.play_action("MOVE", {"input_direction":_input_tracking["move"], "aim_direction":_cam_pivot.get_cam_forward()})
		"run":
			if _input_tracking[key]:
				_action_container.play_action("RUN")
			else:
				_action_container.stop_action("RUN")
		"jump":
			if _input_tracking[key]:
				var should_jump: bool = true
				if double_tap:
					should_jump = not _action_container.play_action("TOGGLE_MOVE_STATE")
				if should_jump:
					_action_container.play_action("JUMP")
		"dash":
			if _input_tracking[key]:
				_action_container.play_action("DASH")

func evaluate_all_input() -> void:
	for action in _input_tracking.keys():
		evaluate_input(action)


func _on_action_exit(_action_id: StringName) -> void:
	evaluate_all_input()
