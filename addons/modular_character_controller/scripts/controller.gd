extends Node
class_name Controller

## Converts input to action requests for [ActionPlayer]


var action_player: ActionPlayer

@export var controlled_obj: Node:
	set(value):
		controlled_obj = value
		action_player = controlled_obj.get_node("ActionPlayer")
		_on_controlled_obj_change()


func _on_controlled_obj_change() -> void:
	pass
