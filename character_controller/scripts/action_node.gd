extends Node
class_name ActionNode

## this is an abstract class not meant to be used directly. Inherit to implement.
## 
## Defines an action that the object can perform during gameplay
## EX: jump, run, attack, activate ability, swap weapon

# WARNING: actions must not enter and exit in the same frame
signal enter(action_id: StringName)
signal exit(action_id: StringName)

# is var so subclass can change, but should not be changed after that
var ACTION_ID: StringName = ""
var IS_LAYERED: bool = false # non-layered actions can only have one active at a time

# allows other actions to stop this one while it is active
@export var interrupt_whitelist: Array[StringName]

var container: ActionContainer
var is_playing: bool = false
var is_enabled: bool = false


func can_play() -> bool:
	return false

func play(_params: Dictionary = {}) -> void:
	if !is_enabled:
		return
	
	is_playing = true
	enter.emit(ACTION_ID)

func stop() -> void:
	if !is_enabled:
		return
	
	if is_playing:
		is_playing = false
		exit.emit(ACTION_ID)
