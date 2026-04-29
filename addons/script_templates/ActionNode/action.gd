# meta-name: Action
# meta-description: Script with all override functions from ActionNode.
# meta-default: true
extends ActionNode



func _on_enable() -> void:
	pass

func _on_disable() -> void:
	pass

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
