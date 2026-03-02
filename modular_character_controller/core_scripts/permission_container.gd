extends Resource
class_name PermissionContainer

## Container of [ActionNode] [member Node.name]s. Use to group [ActionNode]s into profiles.
## Each profile is an [Array] of unique [StringName]s (no duplicate names in a single profile).


## Key: profile name (EX: &"Grounded") [br]
## Data: [Array] of [member Node.name]s (EX: ["jump", "move", "run"]) [br]
## Names used in a profile must be unique. Names may be shared across multiple profiles. [br]
## Example:
## [codeblock]
## {
##  "grounded" : ["Move","Jump"],
##  "flying"   : ["Move","Ascend","Descend"]
## }
## [/codeblock]
@export var _profiles: Dictionary[StringName, Array] = {}


func _to_string() -> String:
	return str(_profiles)

## If [PermissionContainer] is useable.
func is_valid() -> bool:
	return !_profiles.is_empty()

## If [param profile_name] is a valid name to be placed in a profile.
func validate_profile_name(profile_name: StringName) -> bool:
	return profile_name != &"" and profile_name.to_lower() != &"all"

## If [param profile_name] exists in container.
func has_profile(profile_name: StringName) -> bool:
	return _profiles.has(profile_name)

## If [PermissionContainer] has [param name] in any profile.
func has_name(name: StringName) -> bool:
	for name_array: Array in _profiles.values():
		if name in name_array:
			return true
	return false

## Get all names in profile. Returns an empty [Array] if profile does not exist.
func get_permissions(profile_name: StringName) -> Array[StringName]:
	var result: Array[StringName] = []
	if has_profile(profile_name):
		result.assign(_profiles[profile_name])
	return result


## Sets profile to [param name_array]. Set [param profile_name] to [code]&"all"[/code] to set all profiles to [param name_array]. [br]
## Prevents duplicate names from being added. [br]
## Adds new profile if [param profile_name] does not exist yet.
func set_permissions(profile_name: StringName, name_array: Array[StringName]) -> void:
	if validate_profile_name(profile_name):
		_set_profile(profile_name, name_array, has_profile(profile_name))
	elif profile_name.to_lower() == &"all":
		for key: StringName in _profiles.keys():
			_set_profile(key, name_array, true)

## Adds names in [param name_array] to existing profile. Set [param profile_name] to [code]&"all"[/code] to add to all profiles. [br]
## Prevents duplicate names from being added.
func append_permissions(profile_name: StringName, name_array: Array[StringName]) -> void:
	if has_profile(profile_name):
		_set_profile(profile_name, name_array, false)
	elif profile_name.to_lower() == &"all":
		for key: StringName in _profiles.keys():
			_set_profile(key, name_array, false)

## Removes profile from [PermissionContainer]. [br]
## Set [param name_array] to remove names from profile. [br]
## Set [param profile_name] to [code]&"all"[/code] to effect all profiles.
func remove(profile_name: StringName, name_array: Array[StringName] = []) -> void:
	if has_profile(profile_name):
		_remove_profile(profile_name, name_array)
	elif profile_name.to_lower() == &"all":
		for key: StringName in _profiles.keys():
			_remove_profile(key, name_array)


## Sets names in profile. Adds profile if [param profile_name] does not exist yet. [br]
## Prevents duplicate names from being added. [br]
## Set [param clear_first] to [code]true[/code] to empty profile before adding names.
func _set_profile(profile_name: StringName, name_array: Array[StringName], clear_first: bool) -> void:
	if !_profiles.has(profile_name):
		_profiles[profile_name] = []
	if clear_first: 
		_profiles[profile_name].clear()
	for name: StringName in name_array:
		if !_profiles[profile_name].has(name): # no duplicates
			_profiles[profile_name].append(name)

## Removes entire profile or names from profile if [param name_array] is not empty.
func _remove_profile(profile_name: StringName, name_array: Array[StringName] = []) -> void:
	if !_profiles.has(profile_name):
		return
	if name_array.is_empty():
		_profiles.erase(profile_name)
	else:
		var new_array: Array[StringName]
		new_array.assign(_profiles[profile_name].filter(
			func(name: StringName): return name not in name_array ))
		_profiles[profile_name] = new_array
