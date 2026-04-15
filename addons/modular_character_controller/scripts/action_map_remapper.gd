extends Node
class_name ActionMapRemapper


@export var active_map: StringName:
	set = set_active_map
@export var maps: Dictionary[StringName, Dictionary]: # {map name: {request: action path}}
	set(value):
		for key: StringName in value.keys():
			value[key] = _conver_dict(value[key])
		maps = value
@export var debug_log: bool

var _action_player: ActionPlayer


func _ready() -> void:
	_action_player = get_parent() as ActionPlayer
	
	if !active_map and maps:
		active_map = maps.keys()[0]
	
	var ready_cont: Callable = func():
		if maps.has(active_map):
			_action_player.set_action_map(self, false, _conver_dict(maps[active_map]))
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
		_action_player.set_action_map(self, false, _conver_dict(maps[active_map]))
		if debug_log: CustomLogger._log_message(str(self) + " - active map set: " + active_map)
	else:
		if debug_log: CustomLogger._log_message(str(self) + " - active map set failed: " + map_name)

func _conver_dict(dict: Dictionary) -> Dictionary[StringName, NodePath]:
	var result: Dictionary[StringName, NodePath]
	if !dict.is_same_typed(result):
		result.assign(dict)
	else:
		result = dict
	
	return result
