extends Node
class_name ActionContainer

## acts as the API for controlling a character 
##
## contains the ActionNode of a character and manages the use of them by outside classes
# manages actions by their ACTION_ID
# can utilize an ActionContainerConfig to allow swapping actions at runtime

signal action_enter(action_id: StringName)
signal action_exit(action_id: StringName)

## Holds "profiles" of different configurations that can be swapped between at runtime.
## "Profiles" are the dictionary key while the array holds actions available when the profile is active.
## Only needed if different actions should be available at different times
@export var _config_profiles: ActionContainerConfig
@export var _starting_config: StringName = ""

## Config warnings will be pushed when there are actions added that do not currently exist as a child to ActionContainer.
## Disable if config will be holding actions that are expected to be added at runtime.
@export var _disable_config_warnings: bool = false

## stores actions by ACTION_ID
var _active_action_dict: Dictionary[StringName, ActionNode]
var _active_action: StringName = ""

## Filters which actions can be added to _active_action_dict by ActionNode.name.
## Names that are not yet children of ActionContainer may be added.
var _active_config: Array


func _ready() -> void:
	if _config_profiles:
		if !_disable_config_warnings:
			_validate_config()
		if !_starting_config:
			_starting_config = _config_profiles.config_dict.keys()[0]
		reconfigure_from_profile(_starting_config)
	else:
		var children: Array[Node] = get_children()
		for child in children:
			if child is ActionNode:
				add_action(child)
	
	child_entered_tree.connect(_on_child_enter)


func add_action(action: ActionNode) -> void:
	if _active_config and !_active_config.has(action.name):
		return
	
	if _active_action_dict.has(action.ACTION_ID):
		if _active_action_dict[action.ACTION_ID].name == action.name:
			# duplicate action
			return
		else:
			# override action with shared ID
			remove_action(_active_action_dict[action.ACTION_ID])
	
	_active_action_dict[action.ACTION_ID] = action
	action.is_enabled = true
	action.container = self
	action.exit.connect(_on_action_exit)
	action.enter.connect(_on_action_enter)

func remove_action(action: ActionNode) -> void:
	if !has_action(action):
		return
	
	_active_action_dict.erase(action.ACTION_ID)
	if action.exit.is_connected(_on_action_exit):
		action.exit.disconnect(_on_action_exit)
	if action.enter.is_connected(_on_action_enter):
		action.enter.disconnect(_on_action_enter)
	
	if _active_action == action.ACTION_ID or action.IS_LAYERED:
		stop_action(_active_action)
		_active_action = ""
	
	action.container = null
	action.is_enabled = false

func has_action(action: ActionNode) -> bool:
	# action IDs may overlap but node names will not
	return _active_action_dict.has(action.ACTION_ID) and _active_action_dict[action.ACTION_ID].name == action.name

func clear_actions() -> void:
	for key in _active_action_dict.keys():
		remove_action(_active_action_dict[key])

func get_action(action_id: StringName) -> ActionNode:
	if !_active_action_dict.has(action_id):
		return
	return _active_action_dict[action_id]

func get_active_action() -> ActionNode:
	if !_active_action:
		return
	return _active_action_dict[_active_action]


func reconfigure(config: Array) -> void:
	if !config:
		return
	
	_active_config = config
	for child in get_children():
		if child is ActionNode:
			if !config.has(child.name) and has_action(child):
				remove_action(child)
			elif config.has(child.name) and !has_action(child):
				add_action(child)
	# debug
	#print("_______________________________________________________________________")
	#var cur = ""
	#var keys = _active_action_dict.keys()
	#for key in keys:
		#cur += _active_action_dict[key].name + " | "
	#print("cur:  ", cur)

## only works if var _config_profiles is set
func reconfigure_from_profile(profile: StringName) -> void:
	if !_config_profiles or !_config_profiles.config_dict.has(profile):
		return
	reconfigure(_config_profiles.config_dict[profile])


func play_action(action_id: StringName, params: Dictionary = {}) -> bool:
	if action_id not in _active_action_dict:
		return false
	
	var action = _active_action_dict[action_id]
	
	if !action.is_enabled or \
		( !_active_action.is_empty() and !_active_action_dict[_active_action].interrupt_whitelist.has(action_id) ) or \
		!action.can_play():
		return false
		
	if action.IS_LAYERED:
		action.play(params)
		return true
	
	if _active_action:
		_active_action_dict[_active_action].stop()
	
	_active_action = action_id
	action.play(params)
	return true

func stop_action(action_id: StringName) -> void:
	if action_id not in _active_action_dict:
		return
	
	if _active_action_dict[action_id].IS_LAYERED:
		_active_action_dict[action_id].stop()
	elif action_id == _active_action:
		_active_action_dict[_active_action].stop()


func _validate_config() -> void:
	# check starting config is in dict
	if !_config_profiles.config_dict.has(_starting_config):
		push_warning("Action Container Config on ", get_parent().name, " does not have Config name \'", _starting_config, "\'")
	# check that all names in each config profile is the name of an existing child
	var action_names: Array[StringName]
	for child in get_children():
		if child is ActionNode:
			action_names.push_back(child.name)
	for profile_name in _config_profiles.config_dict.keys():
		for profile_action in _config_profiles.config_dict[profile_name]:
			if !action_names.has(profile_action):
				push_warning("Action Container Config on ", get_parent().name, " holds nonexistant action node name \'", profile_action, "\' in profile \'", profile_name, "\'")


func _on_child_enter(node: Node) -> void:
	if node is not ActionNode:
		return
	add_action(node)

func _on_action_exit(action_id: StringName) -> void:
	if action_id == _active_action:
		_active_action = ""
	action_exit.emit(action_id)

func _on_action_enter(action_id: StringName) -> void:
	action_enter.emit(action_id)
