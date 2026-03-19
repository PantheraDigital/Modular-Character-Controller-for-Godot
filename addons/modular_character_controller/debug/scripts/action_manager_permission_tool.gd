@tool
extends Node
class_name ActionManagerPermissionTool

## Tool for automatic setting of [PermissionContainer] in [ActionManager] assuming 
## [ActionManager] uses a tree structure to define its permission profiles. [br]
##
## For example
## [codeblock]
## ActionManager
## |- Profile1
## | |- action1
## |- Profile2
## | |- action2
## 
## # extracted as
## {
## "Profile1": ["action1"],
## "Profile2": ["action2"]
## } 
## [/codeblock]


## Toggle to run script.
@export var extract_configs: bool:
	set(value):
		if not Engine.is_editor_hint():
			return
		if action_manager:
			extract_configs = value
			_update()
		else:
			extract_configs = false
			printerr("action tool has no manager")

## Set true to have script run automatically when [signal ActionManager.child_order_changed] emits.
@export var auto_extract_configs: bool:
	set(value):
		if not Engine.is_editor_hint():
			return
		if action_manager:
			if value and !action_manager.child_order_changed.is_connected(_update):
				action_manager.child_order_changed.connect(_update)
			elif !value and !action_manager.child_order_changed.is_connected(_update):
				action_manager.child_order_changed.disconnect(_update)
			auto_extract_configs = value
		else:
			auto_extract_configs = false
			printerr("action tool has no manager")

## The [ActionManager] to scan for profiles.
@export var action_manager: ActionManager



func _enter_tree() -> void:
	action_manager = get_parent().find_child("ActionManager", false)


func _update() -> void:
	if not Engine.is_editor_hint():
		return
	if action_manager:
		set_manager_config(action_manager)
		print("permissions set in ", action_manager, " of ", action_manager.owner)
	else:
		printerr("no manager found")


## Extracts profiles from [param manager] using [method extract_config_profiles], then applies them to [member ActionManager._action_permissions]. [br]
## Will rename [ActionNodes] if duplicate exists. See [PermissionContainer] for why names must be unique.
static func set_manager_config(manager: ActionManager) -> void:
	if !manager:
		return
	manager._action_permissions = PermissionContainer.new()
	var profiles: Dictionary[StringName, Array] = extract_config_profiles(manager)
	for profile_name: StringName in profiles.keys():
		manager._action_permissions.set_permissions(profile_name, profiles[profile_name])

## Loops over children of [param node] finding [ActionNode]s, returning a [Dictionary] representing "profiles" for [PermissionContainer]. [br]
## Non-ActionNode Nodes without a script are treated as either a profile or "global". [br]
## Profiles hold all [ActionNode] [member Node.name]s and global names. [br]
## Global names are added to profiles that are children of that [Node]. [ActionManager] is treated as "global".
## 
## [codeblock]
## ActionManager
## |- global_action
## |- private_action_
## |- Profile1
## | |- action1
## |- ProfileGroup_
## | |- other_action
## | |- Profile2
## | | |- action2
## | |- Profile3
## | | |- action3
##
## # extract_config_profiles(ActionManager) expected output
## {"Profile1": ["global_action", "action1"], 
##  "Profile2": ["global_action", "other_action", "action2"], 
##  "Profile3": ["global_action", "other_action", "action3"]}
## [/codeblock]
static func extract_config_profiles(node: Node, used_names: Dictionary[StringName, int] = {}) -> Dictionary[StringName, Array]:
	var profile_name: StringName = node.name if node is not ActionManager else &"b_"
	var profile_vals: Array[StringName] = []
	var result: Dictionary[StringName, Array] = {}
	
	for child: Node in node.get_children():
		if child is ActionNode:
			if child.name.ends_with("_") or child.name.ends_with("-"):
				continue
			
			if used_names.has(child.name):
				used_names[child.name] += 1
				child.name = StringName(child.name + str(used_names[child.name]))
			else:
				used_names[child.name] = 0
			
			profile_vals.append(child.name)
		elif child.get_child_count() > 0 and !child.get_script():
			var child_profiles: Dictionary[StringName, Array] = extract_config_profiles(child, used_names)
			result.merge(child_profiles)
	
	if !profile_name.ends_with("_") and !profile_name.ends_with("-"):
		for profile: Array in result.values(): # add child prof vals to parent prof
			profile_vals.append_array(profile)
		result[profile_name] = profile_vals
	else:
		if result: # add parent prof vals to child prof
			for profile: Array in result.values():
				profile.append_array(profile_vals)
		else: # no child profiles
			result[profile_name] = profile_vals
	
	if result.has("b_"):
		return {"global": result["b_"]}
	return result
