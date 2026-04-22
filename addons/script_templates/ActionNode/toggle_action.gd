# meta-name: Toggle Action
# meta-description: Action that will run until told to stop. 
# meta-default: true
extends ActionNode



func _can_play() -> bool:
	return true

func _on_enter() -> void:
	pass

func _on_play(_params: Dictionary = {}) -> void:
	pass

func _on_stop() -> void:
	pass

func _on_exit() -> void:
	pass
