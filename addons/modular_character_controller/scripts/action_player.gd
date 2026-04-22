extends Node
class_name ActionPlayer

## Maps requests to [ActionNode]s, allowing [ActionNode]s to be played and stopped through the use of requests from other objects.
##
## Requests may or may not have an [ActionNode] mapped to it, and are closely related to input actions used by [InputMap]. [br]
## [ActionNode]s must be children of [ActionPlayer] to be used in [member ActionPlayer.action_map]. [br]
## Actions that are in the [member ActionPlayer.action_map] are considered "mapped" and are enabled when mapped and disabled when unmapped. [br]
## Actions can only be mapped to a single request at a time. [br]
## A simplified [NodePath] is used for mapping of [ActionNode]s is used, by using [method ActionPlayer.name_from_path], for simpler comparison. 
## This also means all [ActionNode]s must have a unique [member Node.name]. [br]
## [codeblock]
### Expected hierarchy:
## Character
## |-ActionPlayer
## ||-ActionNode
## [/codeblock]

## Any time [member ActionPlayer.action_map] is changed with the proper functions in [ActionPlayer].
signal action_map_changed(action_map: Dictionary[StringName, NodePath])

## Holds requests and the [NodePath] to the [ActionNode] tied to the requests. [br]
## [NodePath]s are simplified using [method ActionPlayer.name_from_path], which means all [ActionNode]s must have a unique [member Node.name]. [br][br]
## [b] Do not set directly. Use [method ActionPlayer.set_request] or [method ActionPlayer.set_action_map]. [/b]
@export var action_map: Dictionary[StringName, NodePath] # Request, NodePath

@export var debug_log: bool

## Stores [ActionNode]s that may be used by the [ActionPlayer]. Nodes are automatically added if they are children of [ActionPlayer].
var _action_container: Dictionary[NodePath, ActionNode]

## Stores [ActionNode]s that are playing. [br]
## [signal ActionNode.enter_action] and [signal ActionNode.exit_action] are used to add and remove [ActionNode]s from this [Array].
## Action signals are connected and disconnected with [signal Node.child_entered_tree] and [signal Node.child_exiting_tree].
var _playing_actions: Array[ActionNode]


## Returns just the [member Node.name] of the node from the path.
static func name_from_path(node_path: NodePath) -> NodePath:
	var name_count: int = node_path.get_name_count()
	if name_count > 1:
		return NodePath(node_path.get_name(name_count - 1))
	else:
		return node_path


func _ready() -> void:
	for child: Node in get_children():
		var action: ActionNode = child as ActionNode
		if !action:
			continue
		
		var simple_path: NodePath = name_from_path(action.get_path())
		_action_container[simple_path] = action
		_connect_action(action)
	
	for request: StringName in action_map.keys():
		if !action_map[request]:
			continue
		action_map[request] = name_from_path(action_map[request])
		if _action_container.has(action_map[request]):
			_register_action(_action_container[action_map[request]])
		else:
			action_map[request] = NodePath()
	
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	
	if debug_log: CustomLogger._log_message(
		str(self) + " - READY: \n\taction map: " + str(action_map) +
		"\n\taction container: " + str(_action_container) +
		"\n\tplaying actions: " + str(_playing_actions)
		)


## Play an action using the request it is mapped to. [br]
## [param params] is passed to the [ActionNode].
## [codeblock]
## action_player.play(self, &"move", { &"direction":Vector2(1,0) })
## action_player.play(self, &"attack")
## [/codeblock]
func play(caller: Object, request: StringName, params: Dictionary = {}) -> void:
	_command_action(caller, request, true, params)

## Stop an action, if it is playing, using the request it is mapped to.
## [codeblock]
## action_player.stop(self, &"move")
## action_player.stop(self, &"attack")
## [/codeblock]
func stop(caller: Object, request: StringName) -> void:
	_command_action(caller, request, false)

## Set the mapping of a request to an action. [br]
## Will add the request to [member ActionPlayer.action_map] if it does not exist. [br]
## [param action_path] must be to an [ActionNode] that is a direct child to [ActionPlayer], or an empty path. [br][br]
## Emits [signal ActionPlayer.action_map_changed]. [br][br]
## An [ActionNode] that gets mapped to a request becomes enabled. [br]
## An [ActionNode] that gets unmapped from a request becomes disabled.
## [codeblock]
## action_player.set_request(self, &"move", move_action.get_path()) 
## action_player.set_request(self, &"attack", ^"Attack") 
## action_player.set_request(self, &"look", ^"") 
## [/codeblock]
func set_request(caller: Object, request: StringName, action_path: NodePath) -> void:
	var new_path: NodePath = name_from_path(action_path)
	var new_action: ActionNode = _action_container[new_path] if !new_path.is_empty() and _action_container.has(new_path) else null
	var map_has_request: bool = action_map.has(request)
	var old_path: NodePath = action_map[request] if map_has_request else NodePath()
	var old_action: ActionNode = _action_container[old_path] if !old_path.is_empty() and _action_container.has(old_path) else null
	
	if !new_path.is_empty() and !new_action:
		if debug_log: CustomLogger._log_message(str(self) + " - (set_request) Failed: \"" + str(new_path) + "\" invalid path\t | Caller: " + str(caller))
		return
	
	if map_has_request and old_path == new_path:
		if debug_log: CustomLogger._log_message(str(self) + " - (set_request) Failed: \"" + str(new_path) + "\" already mapped to \"" + request + "\"\t | Caller: " + str(caller))
		return
	
	if new_action and action_map.values().has(new_path):
		if debug_log:
			var index: int = action_map.keys().find_custom(func(req: StringName): return action_map[req] == new_path)
			request = action_map.keys()[index]
			CustomLogger._log_message(str(self) + " - (set_request) Failed: \"" + str(new_path) + "\" already mapped to \"" + request + "\"\t | Caller: " + str(caller))
		return
	
	if map_has_request and old_action:
		_deregister_action(old_action)
	
	action_map[request] = new_path
	if new_action:
		_register_action(new_action)
	
	if debug_log: 
		var message: String = "{0} (set_request): \"{1}\" -> \"{2}\" ({3})\t | Caller: {4}".format([str(self), request, new_path, new_action, caller])
		CustomLogger._log_message(message)
	
	action_map_changed.emit(action_map)

## Sets [member ActionPlayer.action_map] to [param new_map]. [br]
## Disables [ActionNode]s leaving action map. Enables [ActionNode]s entering action map. 
## Does nothing to [ActionNode]s that are shared between [member ActionPlayer.action_map] and [param new_map]. [br]
## [param stop_shared_actions] stops [ActionNodes] that are playing and shared between [member ActionPlayer.action_map] and [param new_map]. 
## Leave false to keep actions playing after the map is set. [br][br]
## Emits [signal ActionPlayer.action_map_changed].
func set_action_map(caller: Object, new_map: Dictionary[StringName, NodePath], stop_shared_actions: bool = false) -> void:
	var old_paths: Array[NodePath] = action_map.values()
	var new_paths: Array[NodePath] = []
	
	# fix paths/remove doubles
	# actions in new map not in old map
	# shared actions
	for request: StringName in new_map.keys():
		var fixed_path: NodePath = name_from_path(new_map[request])
		if !new_paths.has(fixed_path) and _action_container.has(fixed_path):
			new_map[request] = fixed_path
			new_paths.append(fixed_path)
		else:
			new_map[request] = NodePath()
			fixed_path = NodePath()
		
		if !fixed_path:
			continue 
		
		if !old_paths.has(fixed_path):
			_register_action(_action_container[fixed_path])
		elif stop_shared_actions:
			_action_container[fixed_path].stop()
	
	# actions in old map not in new map
	for path: NodePath in old_paths:
		if path and !new_paths.has(path):
			_deregister_action(_action_container[path])
	
	action_map = new_map
	
	if debug_log: CustomLogger._log_message(str(self) + " - action map set: " + str(action_map) + "\t | Caller: " + str(caller))
	action_map_changed.emit(action_map)

## Return an [Array] of [ActionNode]s that are in [member ActionPlayer.action_map].
func get_actions() -> Array[ActionNode]:
	var result: Array[ActionNode] = []
	for path: NodePath in action_map.values():
		if _action_container.has(path):
			result.push_back(_action_container[path])
	return result

## Return an [Array] of [ActionNode]s that are currently playing.
func get_playing_actions() -> Array[ActionNode]:
	return _playing_actions.duplicate()


## Stop or Play an action using a request. [br]
## Must be in [member ActionPlayer.action_map] and [member ActionPlayer._action_container].
func _command_action(caller: Object, request: StringName, play: bool, params: Dictionary = {}) -> void:
	if !action_map.has(request):
		if debug_log: 
			var message: String = "{0} ({1}) Failed: No such request \"{2}\"\t | Caller: {3}".format([str(self), ("play" if play else "stop"), request, caller])
			CustomLogger._log_message(message)
		return
	
	var action_path: NodePath = action_map[request]
	
	if !_action_container.has(action_path):
		if debug_log: 
			var message: String = "{0} ({1}) Failed: \"{2}\" -> \"{3}\" (No Action Node)\t | Caller: {4}".format([str(self), ("play" if play else "stop"), request, action_map[request], caller])
			CustomLogger._log_message(message)
		return
	
	var result: bool 
	var action: ActionNode = _action_container[action_path]
	if play:
		result = action.play(params)
	else:
		result = action.stop()
	
	if debug_log:
		var message: String = "{0} ({1}) {2}: \"{3}\" -> \"{4}\" ({5})\t | Caller: {6}".format(
			[str(self), ("play" if play else "stop"), ("Success" if result else "Failed"), request, action_path, action, caller])
		CustomLogger._log_message(message)


## Prepare an [ActionNode] to be added to the [member ActionPlayer.action_map].
func _register_action(action: ActionNode) -> void:
	action.enable()
	
	if debug_log: CustomLogger._log_message(str(self) + " - registered action: " + str(action))

## Prepare an [ActionNode] to be removed from the [member ActionPlayer.action_map].
func _deregister_action(action: ActionNode) -> void:
	action.disable()
	
	if debug_log: CustomLogger._log_message(str(self) + " - deregistered action: " + str(action))


func _add_playing_action(action: ActionNode) -> void:
	if !_playing_actions.has(action):
		_playing_actions.push_back(action)
		if debug_log: CustomLogger._log_message(str(self) + " - add playing action: " + str(action))

func _remove_playing_action(action: ActionNode) -> void:
	if _playing_actions.has(action):
		_playing_actions.remove_at(_playing_actions.find(action))
		if debug_log: CustomLogger._log_message(str(self) + " - remove playing action: " + str(action))


func _connect_action(action: ActionNode) -> void:
	action.enter_action.connect(_add_playing_action)
	action.exit_action.connect(_remove_playing_action)

func _disconnect_action(action: ActionNode) -> void:
	action.enter_action.disconnect(_add_playing_action)
	action.exit_action.disconnect(_remove_playing_action)


func _on_child_entered_tree(node: Node) -> void:
	var action: ActionNode = node as ActionNode
	if !action:
		return
	var simple_path: NodePath = name_from_path(action.get_path())
	if _action_container.has(simple_path):
		return
	
	_action_container[simple_path] = action
	_connect_action(action)
	
	if debug_log: CustomLogger._log_message(str(self) + " - action entered tree: " + str(action))

func _on_child_exiting_tree(node: Node) -> void:
	var action: ActionNode = node as ActionNode
	if !action: 
		return
	var simple_path: NodePath = name_from_path(action.get_path())
	if !_action_container.has(simple_path):
		return
	
	var changed: bool
	for key: StringName in action_map.keys():
		if action_map[key] == simple_path:
			action_map[key] = NodePath()
			changed = true
	
	_remove_playing_action(action)
	_disconnect_action(action)
	_action_container.erase(simple_path)
	
	if changed:
		action_map_changed.emit(action_map)
	
	if debug_log: CustomLogger._log_message(str(self) + " - action exited tree: " + str(action))
