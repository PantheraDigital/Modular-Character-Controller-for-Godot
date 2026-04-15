# meta-name: One Shot Action
# meta-description: Action that will run then stop on its own. 
extends ActionNode



func _can_play() -> bool:
	return true

func _enter() -> void:
	pass

func _play(_params: Dictionary = {}) -> void:
	# add code here
	
	play_action.connect(func(_action): stop(), CONNECT_ONE_SHOT) # queue stop at end of play
