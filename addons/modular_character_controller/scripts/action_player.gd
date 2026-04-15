extends Node
class_name ActionPlayer


signal action_map_changed(action_map: Dictionary[StringName, NodePath])

@export var stop_all_actions_on_full_remap: bool
@export var action_map: Dictionary[StringName, NodePath] # Request, NodePath

@export var debug_log: bool

var _action_container: Dictionary[NodePath, ActionNode]
var _playing_actions: Array[ActionNode]


# actions signals are connected and held in _action_container
# only actions in _action_container can be mapped in action_map
# mapped actions are registered (enabled)
#   only actions mapped may be called by requests
# only mapped actions get deregistered (disabled) durring mapping changes
#   unmapped actions may be manually enabled and called directly



## Gets just the name of the node from the path
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


func play(caller: Object, request: StringName, params: Dictionary = {}) -> void:
	_command_action(caller, request, true, params)

func stop(caller: Object, request: StringName) -> void:
	_command_action(caller, request, false)


func set_request(caller: Object, request: StringName, action_path: NodePath) -> void:
	action_path = name_from_path(action_path)
	
	if !_action_container.has(action_path) and !action_path.is_empty():
		if debug_log: CustomLogger._log_message(str(self) + " - (set_request) Failed: " + str(action_path) + " Invalid\t | Caller: " + str(caller))
		return
	
	if action_map.has(request) and !action_map[request].is_empty() and action_map[request] != action_path:
		_deregister_action(_action_container[action_map[request]]) # old action
	
	var action: ActionNode = _action_container[action_path] if !action_path.is_empty() else null
	action_map[request] = action_path
	if action:
		_register_action(action)
	
	if debug_log: 
		var message: String = "{0} (set_request): \"{1}\" -> \"{2}\" ({3})\t | Caller: {4}".format([str(self), request, action_path, action, caller])
		CustomLogger._log_message(message)
	
	action_map_changed.emit(action_map)

func set_action_map(caller: Object, stop_all_actions: bool, new_map: Dictionary[StringName, NodePath]) -> void:
	# deregister out going actions
	# register incoming actions
	# keep shared actions (stop actions if stop_all_actions == true)
	var combined_requests: Array[StringName] = action_map.keys()
	for request: StringName in new_map.keys():
		if !combined_requests.has(request):
			combined_requests.push_back(request)
	
	for request: StringName in combined_requests:
		var action_map_has: bool = action_map.has(request)
		var action_map_path: NodePath = action_map[request] if action_map_has else NodePath()
		var new_map_has: bool = new_map.has(request)
		var new_map_path: NodePath = new_map[request] if new_map_has else NodePath()
		
		if new_map_has: # fix new path
			new_map_path = name_from_path(new_map_path)
			new_map[request] = new_map_path
			if !_action_container.has(new_map_path):
				new_map_path = NodePath()
				new_map[request] = NodePath()
		
		if !action_map_path and !new_map_path:
			continue
		
		# new_map_path and action_map_path will be in _action_container if they are valid
		
		# shared request
		if action_map_has and new_map_has:
			if action_map_path == new_map_path:
				if stop_all_actions:
					_action_container[new_map_path].stop()
			else:
				if action_map_path:
					_deregister_action(_action_container[action_map_path])
				if new_map_path:
					_register_action(_action_container[new_map_path])
		# outgoing request
		elif action_map_has and !new_map_has: 
			if action_map_path:
				_deregister_action(_action_container[action_map_path])
		# incoming request
		elif !action_map_has and new_map_has: 
			if new_map_path:
				_register_action(_action_container[new_map_path])
	
	action_map = new_map
	
	if !Engine.is_editor_hint() and debug_log: CustomLogger._log_message(str(self) + " - action map set: " + str(action_map))
	action_map_changed.emit(action_map)

func get_actions() -> Array[ActionNode]:
	var result: Array[ActionNode] = []
	for path: NodePath in action_map.values():
		if _action_container.has(path):
			result.push_back(_action_container[path])
	return result

func get_playing_actions() -> Array[ActionNode]:
	return _playing_actions.duplicate()


func _command_action(caller: Object, request: StringName, play: bool, params: Dictionary = {}) -> void:
	if !action_map.has(request):
		if debug_log: 
			var message: String = "{0} ({1}) Failed: No such request {2}\t | Caller: {3}".format([str(self), ("play" if play else "stop"), request, caller])
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


func _register_action(action: ActionNode) -> void:
	if action.is_playing:
		action.stop()
	action.enable()
	
	if debug_log: CustomLogger._log_message(str(self) + " - registered action: " + str(action))

func _deregister_action(action: ActionNode) -> void:
	if action.is_playing:
		action.stop()
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
	
	_action_container.erase(simple_path)
	_deregister_action(action)
	_disconnect_action(action)
	var changed: bool
	for key: StringName in action_map.keys():
		if action_map[key] == simple_path:
			action_map[key] = NodePath()
			changed = true
	
	if changed:
		action_map_changed.emit(action_map)
	
	if debug_log: CustomLogger._log_message(str(self) + " - action exited tree: " + str(action))
