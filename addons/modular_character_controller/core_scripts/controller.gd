extends Node
class_name Controller

## Communicates with [ActionManager] to make charactes do things in game.
var _action_manager: ActionManager

@export var controlled_obj: Node:
	set(value):
		controlled_obj = value
		_action_manager = controlled_obj.get_node("ActionManager")
		_on_controlled_obj_change()


func _on_controlled_obj_change():
	pass
