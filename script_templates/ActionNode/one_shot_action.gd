# meta-name: One Shot Action
# meta-description: Action that will run then stop on its own. 
extends ActionNode


# optional variables. uncomment to include
# set by ActionManager when ActionManager enters tree or when ActionNode is added to ActionManager
#var _character: CharacterBody3D
#var _manager: ActionManager
#var _container: ActionContainer


func _init() -> void:
	self.TYPE = &""


func _can_play() -> bool:
	return true

func _enter() -> void:
	pass

func _play(_params: Dictionary = {}) -> void:
	# add code here
	
	super.__exit()
