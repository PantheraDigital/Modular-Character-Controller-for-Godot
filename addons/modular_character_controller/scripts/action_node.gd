extends Node
class_name ActionNode

## Base class for all actions. Extend to implement functionality.
##
## [ActionNode] handles the game logic needed to make a character perform a singel action. [br]
## Expected hierarchy: 
## [codeblock]
## Character
## |-ActionPlayer
## ||-ActionNode
## [/codeblock]

# call order:
# play() -> can_play() -> _can_play() -> ActionCollider.handle_collision() -> _enter() -> _on_enter() -> signal enter_action -> _play() -> signal play_action
# stop() -> _stop() -> signal stop_action -> _exit() -> _on_exit() -> signal exit_action
#
# Natural exit: when this action calls _exit()
# Interuption: when stop() is called in or out of this class

## Emitted when [method ActionNode.play] is called if the action is not already playing.
signal enter_action(action: ActionNode)
## Emitted when [method ActionNode.play] is called.
signal play_action(action: ActionNode)
## Emitted when [method ActionNode.stop] is called if the action is playing. Represents the action being stopped before it naturally stops itself.
signal stop_action(action: ActionNode)
## Emitted when action ends if the action is playing. Represents the action naturally stopping itself.
signal exit_action(action: ActionNode)


@onready var _action_player: ActionPlayer = get_parent()

## If the action is playing. [br]
## [b] Do not set directly. This is set by [method play] and [method _exit]. [/b]
var is_playing: bool = false
## If the action is enabled. Set this [code]false[/code] to make [method can_play] always return [code]false[/code]. [br]
## [b] Do not set directly. Use [method enable] or [method disable]. [/b]
var is_enabled: bool = false


## Helper function to be used by [ActionNode] signals. [br]
## Exits the [param action] after a short delay using [SceneTreeTimer].
static func delayed_exit(action: ActionNode) -> void:
	var timer: SceneTreeTimer = action.get_tree().create_timer(2.1)
	timer.timeout.connect(action._exit)


func _exit_tree() -> void:
	disable()


## Prepare the action to be in a playable state.
func enable() -> void:
	is_enabled = true
	_on_enable()

## Prepare the action to be in an unplayable state. [br]
## Performs final clean up. [br][br]
## Emits [signal exit_action]
func disable() -> void:
	is_enabled = false
	_on_disable()
	is_playing = false
	exit_action.emit(self)

## If this action can play.
func can_play() -> bool:
	return is_enabled and _on_can_play()

## [param _params] is arbitrary data needed for action to play. [br][br]
## Calls [method can_play] then handles collision with other [ActionNode]s that are playing in [ActionPlayer] using [code]_action_player.get_playing_actions()[/code]. [br]
## Emits [signal enter_action] if action is not playing already, then emits [signal play_action].
func play(_params: Dictionary = {}) -> bool:
	if !can_play(): 
		return false
	
	if !is_playing:
		_enter()
	
	_on_play(_params)
	is_playing = true
	play_action.emit(self)
	return true

## Force exit action if playing. This is considered as an interuption of the action. [br]
## Emits [signal stop_action], then [signal exit_action].
func stop() -> bool:
	if !is_playing: 
		return false
	_on_stop()
	stop_action.emit(self)
	_exit()
	return true


## Called when action is played. Not called again till action is exited. [br]
## Emits [signal enter_action].
func _enter() -> bool:
	if is_playing: 
		return false
	_on_enter()
	enter_action.emit(self)
	return true

## Called whenever action exits, either naturally or from interruption. Calling this function from within this action is considered a natural exit. [br]
## Emits [signal exit_action] and sets [member is_playing] set to [code]false[/code].
func _exit() -> bool:
	if !is_playing: 
		return false
	_on_exit()
	is_playing = false
	exit_action.emit(self)
	return true

## Override these functions to implement action logic.
#region Custom Overrides
## Prepare the action to be in a playable state. [br]
## Use to set any variables that should stay set while this action is enabled, AKA not in a dormant state.
## This is when the action is expected to be called on to play.
func _on_enable() -> void:
	pass

## Clean up for when the action becomes unplayable, such as leaving the [SceneTree]. [br]
## Use for clean up of variables that should not stay set when action is disabled, AKA in a dormant state.
## This is when the action is held somewhere but is not expected to play. [br][br]
## Called before [member is_playing] set to [code]false[/code], and [signal exit_action].
func _on_disable() -> void:
	pass

## Override to determin if the action should play. Only called if the action is enabled.
func _on_can_play() -> bool:
	return true

## Override to run code when action starts. Not called again till action is exited. [br]
## This is for setting variables that need to be set before first play, and will be unset after play by [method _on_exit]. [br][br]
## Called before [signal enter_action] and before [member is_playing] is set to [code]true[/code].
func _on_enter() -> void:
	pass

## [param _params] is arbitrary data passed from the controller to the action. The data expected will be dependant on the implementation in extending classes. [br]
## Override to run code when action is played. Called for every [method play] call if action can play. [br][br]
## Called after [signal enter_action] and [method _on_enter]. [br]
## Called before [member is_playing] set to [code]true[/code], and [signal play_action].
func _on_play(_params: Dictionary = {}) -> void:
	pass

## Override to handle an early exit of this action. [br]
## This is for handling logic that may be needed for when the action is forced to stop but has not naturally stopped yet, such as stopping an animation before it has ended. [br][br]
## Called before [signal stop_action], [member is_playing] set to [code]false[/code], and [signal exit_action]
func _on_stop() -> void:
	pass

## Override to run code every time this action finishes (naturally or from interruption). [br]
## This is for unsetting variables that were set before first play by [method _on_enter]. [br][br]
## Called before [member is_playing] set to [code]false[/code], and [signal exit_action]
func _on_exit() -> void:
	pass
#endregion
