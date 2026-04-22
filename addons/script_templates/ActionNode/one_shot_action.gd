# meta-name: One Shot Action
# meta-description: Action that will run then stop on its own. 
extends ActionNode


func _ready() -> void:
	# can also place in _play()
	play_action.connect(func(action:ActionNode): action._exit()) # queue exit at end of play
	#play_action.connect(delayed_exit) # queue exit after delay

func _can_play() -> bool:
	return true

func _on_enter() -> void:
	pass

func _on_play(_params: Dictionary = {}) -> void:
	pass

func _on_exit() -> void:
	pass
