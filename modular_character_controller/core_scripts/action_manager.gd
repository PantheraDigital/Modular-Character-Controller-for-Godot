extends Node
class_name ActionManager

## Public interface for a character allowing for external classes to request actions. [br]
## The use of leading '_' before functions indicates the level of privacy. [br]
## [code]func_name()[/code] - public function [br]
## [code]_func_name()[/code] - private functions usable by other action system classes such as [ActionNode]. [br]
## [code]__func_name()[/code] - private functions that should only be used by [ActionManager].


## Emitted when an action has been played.
signal action_enter(action_type: StringName)
## Emitted when an action has stopped.
signal action_exit(action_type: StringName)
## Emitted when an action has been added or removed, as well as when permitted actions changes.
signal managed_actions_change(active_profile: StringName, permitted_actions: Array[StringName])

## Used internally by [method _get_action] to determine what kind of actions to get.
enum GetFilterType {USE_PERMISSIONS, IGNORE_PERMISSIONS, PRIVATE_ACTIONS}

## The character that this manager manages actions for.
@export var _character: CharacterBody3D
## The profile this manager uses to filter actions before playing them. [br]
## This is optional if the character is not expected to restrict which actions can be played. [br]
## See [PermissionContainer] for more.
@export var _active_permission_profile: StringName
## Groups of permitted actions. Actions that are permitted can be played while the rest cannot. [br]
## This is optional if the character is not expected to restrict which actions can be played. [br]
## Store actions using their [member Node.name] NOT their [member ActionNode.TYPE]. [br]
## Keep names unique across all actions on a single character.
## [codeblock]
## {
##  "grounded" : ["Move","Jump"],
##  "flying"   : ["Fly","Ascend","Descend"]
## }
## [/codeblock]
## This allows the specific [ActionNode] to be found and allows [member ActionNode.TYPE]s to be used by multiple nodes across differnt profiles. [br]
## For example the above profiles have actions "Move" and "Fly" but the actions may share the [member ActionNode.TYPE] of "move", making it so that [code]ActionManager.play_action(&"move")[/code] will call either "Move" or "Fly" depending on [member _active_permission_profile]. [br][br]
##
## This also means that two actions in the same profile can share a [member ActionNode.TYPE], in which case one action will need a higher [member ActionCollision.priority_index], making it override the other action. [br]
## For example:
## [codeblock]
## { "grounded" : ["Move","Jump","SuperJump"] }
## [/codeblock]
## If a character got a powerup giving them a temporary "SuperJump", this action could be added to the profile making it so [code]ActionManager.play_action(&"jump")[/code] will always call "SuperJump" and not "Jump", assuming "SuperJump" has a higher [member ActionCollision.priority_index]. [br][br]
@export var _action_permissions: PermissionContainer
@export_group("Debug")
## If debug text should be displayed. Uses [CustomLogger].
@export var _log: bool = false

var _action_container: ActionContainer = ActionContainer.new()
## Actions that are currently playing. Actions are added and removed using [method __on_action_enter] and [method __on_action_exit] which are connected to [signal ActionNode.enter_action] and [signal ActionNode.exit_action].
var _playing_actions: Array[ActionNode]


func _enter_tree() -> void:
	if _log: CustomLogger._log_message("--- " + _character.name + " init ---")
	
	var child_actions: Array[ActionNode] = __get_child_actions()
	for action: ActionNode in child_actions:
		__register_action(action)
	
	if _log: 
		CustomLogger._log_message("action container: " + str(_action_container))
		CustomLogger._log_message("action permissions: active profile-" + _active_permission_profile + " | " + str(_action_permissions))
		CustomLogger._log_message("--- " + _character.name + " ready ---")

## Used by external classes, such as a controller, to request this character perform an action.
#region External Use Functions
## Request an action to play. [param action_params] is passed to the [ActionNode] and expected data is dependant on the [ActionNode].
func play_action(action_type: StringName, action_params: Dictionary = {}) -> bool:
	return __play_action(GetFilterType.USE_PERMISSIONS, action_type, action_params)

## Request an action that is playing be stopped.
func stop_action(action_type: StringName) -> bool:
	var index: int = _playing_actions.find_custom(func(action_node: ActionNode): return action_node.TYPE == action_type)
	if index == -1: return false
	
	if _playing_actions[index].is_playing:
		_playing_actions[index].interrupt()
		return true
	return false
#endregion

## Can be used by other Action System classes like ActionNode.
#region Action System Functions
## Request an action to play. [param action_params] is passed to the [ActionNode] and expected data is dependant on the [ActionNode]. [br]
## Only searches actions that are private, that is actions not in any permission profile and expected to only be used internally by this character.
func _play_private_action(action_type: StringName, action_params: Dictionary = {}) -> bool:
	return __play_action(GetFilterType.PRIVATE_ACTIONS, action_type, action_params)

## Set the permission profile to filter which actions can play. [br]
## Emits [signal managed_actions_change].
func _set_active_permission_profile(profile_name: StringName) -> bool:
	if !_action_permissions or !_action_permissions.validate_profile_name(profile_name):
		return false
	_active_permission_profile = profile_name
	if _log: CustomLogger._log_message( "active permission profile: " + _active_permission_profile + ": " + str(_action_permissions.get_permissions(_active_permission_profile)) )
	managed_actions_change.emit(_active_permission_profile, _action_permissions.get_permissions(_active_permission_profile) if _action_permissions else [])
	return true

## Add an [ActionNode] to be managed. Adds [param action] as child to manager if not already. [br]
## The optional [param permission_profiles] may be used to add the [param action] to any existing permission profiles or add a new profile. [br]
## Emits [signal managed_actions_change].
func _add_action(action: ActionNode, permission_profiles: Array[StringName] = []) -> bool:
	if !action or _action_container.has_name(action.name):
		return false
	
	__register_action(action)
	if !self.is_ancestor_of(action):
		add_child(action)
	for profile: StringName in permission_profiles:
		if _action_permissions.has_profile(profile):
			_action_permissions.append_permissions(profile, [action.name])
		else:
			_action_permissions.set_profile(profile, [action.name])
	var temp: Array[StringName] = [] # used due to bug that prevents empty Array being assigned to typed array from ternary
	managed_actions_change.emit(_active_permission_profile, _action_permissions.get_permissions(_active_permission_profile) if _action_permissions else temp)
	return true

## Finds and removes action from manager using [ActionNode]'s [member Node.name]. Calls [method remove_child] and [method queue_free]. [br]
## Emits [signal managed_actions_change].
func _remove_action(action_name: StringName) -> bool:
	var action: ActionNode = _action_container.get_action_by_name(action_name)
	if !action:
		return false
	
	remove_child(action)
	__deregister_action(action)
	_action_permissions.remove(&"all", [action.name])
	var index: int = _playing_actions.find_custom(func(action_node: ActionNode): return action_node.name == action_name)
	if index != -1:
		_playing_actions.remove_at(index)
	
	action.queue_free()
	managed_actions_change.emit(_active_permission_profile, _action_permissions.get_permissions(_active_permission_profile) if _action_permissions else [])
	return true

## Get an [ActionNode] from the managed actions using [member ActionNode.TYPE].
## [param filter_type] specifies how the action should be searched for.
func _get_action(action_type: StringName, filter_type: GetFilterType) -> ActionNode:
	var test_batch: Array[ActionNode]
	
	match filter_type:
		GetFilterType.USE_PERMISSIONS:
			if _action_permissions and _action_permissions.is_valid():
				var name_filter: Array[StringName] = _action_permissions.get_permissions(_active_permission_profile)
				var filter: Callable = \
					func(action:ActionNode): return action.name in name_filter
				test_batch = _action_container.get_actions_by_type(action_type, filter)
				
			else:
				test_batch = _action_container.get_actions_by_type(action_type)
		
		GetFilterType.IGNORE_PERMISSIONS:
			test_batch = _action_container.get_actions_by_type(action_type)
		
		GetFilterType.PRIVATE_ACTIONS:
			var filter: Callable = \
				func(action:ActionNode): return !_action_permissions.has_name(action.name)
			test_batch = _action_container.get_actions_by_type(action_type, filter)
	
	if test_batch.size() == 1:
		return test_batch[0]
	if test_batch.size() == 0:
		return null
	
	return __get_action_with_priority(test_batch)
#endregion

## Should not be accessed from outside this class.
#region Private Functions
## Find and play an action. Performs collision check between action to play and actions in [member _playing_actions]. [br]
## [param filter_type] specifies how the action should be searched for. [br]
## [param action_type] is the [member ActionNode.TYPE]. [br]
## [param action_params] is the data to give to [ActionNode].
func __play_action(filter_type: GetFilterType, action_type: StringName, action_params: Dictionary = {}) -> bool:
	var new_action: ActionNode = _get_action(action_type, filter_type)
	
	if _log:
		CustomLogger._log_message( 
			(_character.name + " play private action: " + action_type + " | " + str(new_action))
			if filter_type == GetFilterType.PRIVATE_ACTIONS else 
			(_character.name + " play action: " + action_type + " | " + str(new_action)) )
	
	if !new_action or !new_action.can_play(): 
		if _log: CustomLogger._log_message( "-- valid: " + "false" if !new_action else 
			new_action.name + " | can play: " + str(new_action.can_play()) )
		return false
	
	# playing actions filter
	if !new_action.collision or _playing_actions.is_empty():
		new_action.play(action_params)
		return true
	
	var collisions: Array[ActionCollision] = []
	for action: ActionNode in _playing_actions:
		if !action.collision:
			continue
		
		match action.collision.collides_with(new_action.collision):
			ActionCollision.CollisionType.PASS:
				continue
			ActionCollision.CollisionType.COLLIDE:
				if _log: CustomLogger._log_message("-- collision check: collides with " + str(action))
				collisions.push_back(action.collision)
			ActionCollision.CollisionType.BLOCK:
				if _log: CustomLogger._log_message("-- collision check: blocked by " + str(action))
				return false
	
	if collisions:
		for collision in collisions:
			new_action.collision.hit(collision)
	
	return new_action.play(action_params)

## Add the [param action] to [member _action_container] if the [ActionNode]'s [member Node.name] is not already used. [br]
## Enables [ActionNode]. Sets [ActionNode]'s [member ActionNode._character] and [member ActionNode._manager] if they are defined in the action.
func __register_action(action: ActionNode) -> void:
	if !action or _action_container.has_name(action.name):
		return
	if "_character" in action:
		action._character = _character
	if "_manager" in action:
		action._manager = self
	_action_container.add_action(action)
	action.enter_action.connect(__on_action_enter)
	action.exit_action.connect(__on_action_exit)
	action.enable()
	if _log: CustomLogger._log_message(str(_character) + " registered: " + action.name)

## Removes the [param action] from [member _action_container] if the [ActionNode]'s [member Node.name] exists. [br]
## Disables [ActionNode].
func __deregister_action(action: ActionNode) -> void:
	if !action or !_action_container.has_name(action.name):
		return
	if "_character" in action:
		action._character = null
	if "_manager" in action:
		action._manager = null
	_action_container.remove_action(action)
	action.enter_action.disconnect(__on_action_enter)
	action.exit_action.disconnect(__on_action_exit)
	action.disable()
	if _log: CustomLogger._log_message(str(_character) + " deregister: " + action.name)

## Returns the [ActionNode] with the highest [member ActionCollision.priority_index]. If an [ActionNode] does not have an [ActionCollision] it is treated as having the lowest priority.
func __get_action_with_priority(actions: Array[ActionNode]) -> ActionNode:
	# use collision to get final action
	var priority_action: ActionNode = null
	for action: ActionNode in actions:
		if !priority_action or !priority_action.collision:
			priority_action = action
			continue
		
		if priority_action.collision and !action.collision:
			continue
		
		if priority_action.collision.priority_index < action.collision.priority_index:
			priority_action = action
	
	return priority_action

## Returns all children that are [ActionNode]. Is recursive. [param node] defaultly set to [code]self[/code].
func __get_child_actions(node: Node = self) -> Array[ActionNode]:
	var result: Array[ActionNode]
	for child: Node in node.get_children():
		if child is ActionNode:
			result.append(child)
		if child.get_child_count() > 0:
			result.append_array(__get_child_actions(child))
	
	return result

#region Signal Connections
func __on_action_enter(action: ActionNode) -> void:
	if !_playing_actions.has(action):
		_playing_actions.append(action)
		action_enter.emit(action.TYPE)

func __on_action_exit(action: ActionNode) -> void:
	if _playing_actions.has(action):
		_playing_actions.erase(action)
		action_exit.emit(action.TYPE)
#endregion
#endregion
