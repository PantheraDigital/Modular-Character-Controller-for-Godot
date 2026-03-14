# meta-name: Toggle Action
# meta-description: Action that will run until told to stop. 
# meta-default: true
extends ActionNode


# optional variables. uncomment to include
# set by ActionManager when ActionManager enters tree or when ActionNode is added to ActionManager
#var _character: CharacterBody3D or CharacterBody2D
#var _manager: ActionManager
#var _container: ActionContainer


func _init() -> void:
	self.TYPE = &""


func _can_play() -> bool:
	return true

func _enter() -> void:
	pass

func _play(_params: Dictionary = {}) -> void:
	pass

func _stop() -> void:
	pass

func _exit() -> void:
	pass
