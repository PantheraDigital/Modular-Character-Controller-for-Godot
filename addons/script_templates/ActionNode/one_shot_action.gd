# meta-name: One Shot Action
# meta-description: Action that will run then stop on its own. 
extends ActionNode


func _ready() -> void:
	play_action.connect(immediate_exit_self) # queue exit at end of play
	#play_action.connect(delayed_exit_self) # queue exit after HELPER_DELAY

func _can_play() -> bool:
	return true

func _on_enter() -> void:
	pass

func _on_play(_params: Dictionary = {}) -> void:
	pass

func _on_exit() -> void:
	pass
