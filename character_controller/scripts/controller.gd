extends Node
class_name Controller

## utilizes ActionNodes to controll a controllable node


@export var controlled_obj: Node:
	set(value):
		controlled_obj = value
		_on_controlled_obj_change()


func _on_controlled_obj_change():
	pass
