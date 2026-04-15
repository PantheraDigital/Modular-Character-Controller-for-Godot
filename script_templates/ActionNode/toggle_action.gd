# meta-name: Toggle Action
# meta-description: Action that will run until told to stop. 
# meta-default: true
extends ActionNode



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
