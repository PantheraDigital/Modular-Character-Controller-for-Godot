extends Node
class_name MovementStateManager



## set with set_active_state()
@export var active_state: MovementState:
	set(value):
		if value.get_parent() != self:
			return
		
		if active_state:
			active_state.exit()
		active_state = value
		active_state.enter()


func _ready() -> void:
	if active_state:
		return
	
	for state in get_children():
		if state is MovementState and !active_state:
			active_state = state
			return


func set_active_state(state_name: StringName) -> void:
	if active_state and state_name == active_state.name:
		return
	
	for state in get_children():
		if state is MovementState and state.name == state_name:
			active_state = state
