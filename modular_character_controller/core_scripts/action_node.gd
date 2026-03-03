extends Node
class_name ActionNode

## Base class for all actions. Extend to implement functionality. [br]
## Override functions with a single leading '_'. Override other actions for more control.
# call order:
# can_play() -> _can_play()
# play() -> __enter() -> enter_action -> _enter() -> play_action -> _play()
# stop() -> stop_action -> _stop() -> __exit() -> exit_action -> _exit()

## Emitted when [method ActionNode.play] is called. Emitted once if [method ActionNode.play] is called multiple times before the action exits.
signal enter_action(action: ActionNode)
## Emitted when [method ActionNode.play] is called. Emitted every time [method ActionNode.play] is called if actin can play.
signal play_action(action: ActionNode)
## Emitted when [method ActionNode.stop] is called. This represents an action exiting before it naturally exited.
signal stop_action(action: ActionNode)
## Emitted when action ends.
signal exit_action(action: ActionNode)


## The type of the action determins which requests it responds to in [ActionManager]. [br]
## Treat as a [code]const[/code] at runtime. This is left as a var so that it can be set by subclasses.
@export var TYPE: StringName = &""

## Determines how this action will interact with other actions in [ActionManager], such as blocking other actions from playing or interrupting an action that is playing.
@export var collision: ActionCollision = ActionCollision.new(self)

# optional variables. uncomment to include
# these are set when ActionManager _on_child_enter() or _on_child_exit() signals fire
#var _character: CharacterBody3D # good for getting other nodes or getting data of character such as velocity
#var _manager: ActionManager # reconfiguring available actions or playing/stopping another action
#var _container: ActionContainer # edits action nodes on character

## If the action is playing.
var is_playing: bool = false
## If the action is enabled. Set this [code]false[/code] to make [method can_play] always return [code]false[/code].
var is_enabled: bool = false


## Allow action to play.
func enable() -> void:
	is_enabled = true

## Prevent action from playing. This causes [method can_play] to always return [code]false[/code].
func disable() -> void:
	is_enabled = false

## If this action can play.
func can_play() -> bool:
	return is_enabled and _can_play()


## [param _params] is arbitrary data passed from the controller to the action. The data expected will be dependant on the implementation in extending classes. [br]
## Uses [method can_play]. [br]
## Emits [signal enter_action] if action is not playing already, then emits [signal play_action].
func play(_params: Dictionary = {}) -> bool:
	if !can_play(): 
		return false
	
	if !is_playing:
		__enter()
		is_playing = true
	
	play_action.emit(self)
	_play(_params)
	return true

## Force exit action if playing. [br]
## Emits [signal stop_action], then [signal exit_action].
func stop() -> bool:
	if !is_playing: 
		return false
	stop_action.emit(self)
	_stop()
	__exit()
	return true


## Override these functions unless signal order needs to be changed.
#region Custom Overrides
## Override to determin if the action should play.
func _can_play() -> bool:
	return true

## Override to run code when action starts. Not called again till action is exited. [br]
## Called after [signal enter_action] and before [member is_playing] is set to [code]true[/code].
func _enter() -> void:
	pass

## [param _params] is arbitrary data passed from the controller to the action. The data expected will be dependant on the implementation in extending classes. [br]
## Override to run code when action is played. Can be called multiple times, even if [member is_playing] is set to [code]true[/code]. [br]
## Will not be called if [method can_play] returns [code]false[/code]. [br]
## Called after [signal enter_action], [method _enter], [member is_playing] set to [code]true[/code], and [signal play_action].
func _play(_params: Dictionary = {}) -> void:
	pass

## Override to handle an early exit of this action. [br]
## Called after [signal stop_action] and before [method __exit]
func _stop() -> void:
	pass

## Override to run code every time this action finishes. [br]
## Called after all signals that may emit when an action exits naturally or from interruption.
func _exit() -> void:
	pass
#endregion


## Should not be accessed from outside this class.
#region Private Functions
## Called when action is played. Not called again till action is exited. [br]
## Emits [signal enter_action].
func __enter() -> bool:
	if is_playing: 
		return false
	enter_action.emit(self)
	_enter()
	return true

## Called whenever action exits, either naturally or from interruption. [br]
## Emits [signal exit_action].
func __exit() -> bool:
	if !is_playing: 
		return false
	is_playing = false
	exit_action.emit(self)
	_exit()
	return true
#endregion
