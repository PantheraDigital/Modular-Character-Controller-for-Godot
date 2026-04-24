extends Node
class_name ActionMapRemapper

## Holds multiple request to action mappings for [ActionPlayer]. Attach to [ActionPlayer] for multiple map management. 
## Expected hierarchy: 
## [codeblock]
## Character
## |-ActionPlayer
## ||-ActionMapRemapper
## [/codeblock]


@export var active_map: StringName:
	set = set_active_map

## {map_name: {request: action_path}}
@export var maps: Dictionary[StringName, Dictionary]: 
	set(value):
		for key: StringName in value.keys():
			value[key] = _convert_dict(value[key])
		maps = value

@export var debug_log: bool

@onready var _action_player: ActionPlayer = get_parent() as ActionPlayer


func _ready() -> void:
	if !active_map and maps:
		active_map = maps.keys()[0]
	
	var ready_cont: Callable = func():
		if maps.has(active_map):
			_action_player.set_action_map(self, _convert_dict(maps[active_map]))
			if debug_log: CustomLogger._log_message(str(self) + " - READY 2/2: ActionPlayer map set")
	
	_action_player.ready.connect(ready_cont, CONNECT_ONE_SHOT)
	
	if debug_log: CustomLogger._log_message(str(self) + " - READY 1/2: \n\tactive map:  " + str(active_map) + "\n\taction maps: " + str(maps))


func set_active_map(map_name: StringName) -> void:
	if !is_node_ready(): # allows setting in inspector
		active_map = map_name
		return
	
	if !_action_player or !maps or map_name == active_map:
		return
	
	if maps.has(map_name):
		active_map = map_name
		_action_player.set_action_map(self, _convert_dict(maps[active_map]))
		if debug_log: CustomLogger._log_message(str(self) + " - active map set: " + active_map)
	else:
		if debug_log: CustomLogger._log_message(str(self) + " - active map set failed: " + map_name)


## Returns [param dict] as typed Dictionary[StringName, NodePath]
func _convert_dict(dict: Dictionary) -> Dictionary[StringName, NodePath]:
	var result: Dictionary[StringName, NodePath]
	if !dict.is_same_typed(result):
		result.assign(dict)
	else:
		result = dict
	
	return result
