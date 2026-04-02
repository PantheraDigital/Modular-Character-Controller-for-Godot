extends Node
class_name Controller


var _action_manager: ActionPlayer

@export var controlled_obj: Node:
	set(value):
		controlled_obj = value
		_action_manager = controlled_obj.get_node("ActionPlayer")
		_on_controlled_obj_change()


func _on_controlled_obj_change():
	pass
