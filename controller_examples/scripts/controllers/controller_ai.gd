extends Controller


const INPUT_DELAY: float = 0.5

var _last_input_window: float = 0.0
var _current_direction: Vector3 = Vector3.FORWARD
var _action_container: ActionContainer
var _cam_pivot: Node3D


func _on_controlled_obj_change():
	_action_container = controlled_obj.get_node("ActionContainer")
	_cam_pivot = controlled_obj.find_child("CamPivot", false)


func _process(delta: float) -> void:
	if _last_input_window < 0.0:
		_current_direction = _current_direction.rotated(Vector3.UP, deg_to_rad(90.0))
		_last_input_window = INPUT_DELAY
	else:
		_last_input_window -= delta
	
	_action_container.play_action("MOVE", {"input_direction":_current_direction})
	if _cam_pivot:
		_cam_pivot.set_direction(Vector2(_current_direction.x, _current_direction.z))
