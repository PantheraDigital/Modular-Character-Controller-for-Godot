extends Node
class_name ActionMapRemapper


signal maps_changed(active_map: StringName, maps: Dictionary[StringName, RequestActionArray])

@export var active_map: StringName:
	set = set_active_map
@export var maps: Dictionary[StringName, RequestActionArray]: # {state name, {request, action name}}
	set(value):
		maps = value
		maps_changed.emit(active_map, maps)
@export var debug_log: bool

var _action_player: ActionPlayer


func _ready() -> void:
	_action_player = get_parent() as ActionPlayer
	
	if !active_map and maps:
		active_map = maps.keys()[0]
	
	if debug_log: CustomLogger._log_message(str(self) + " - READY: \n\tactive map:  " + str(active_map) + "\n\taction maps: " + str(maps))


func set_active_map(map_name: StringName) -> void:
	if !is_node_ready():
		active_map = map_name
		return
	
	if !_action_player or !maps or map_name == active_map:
		return
	
	if maps.has(map_name):
		_action_player.action_map = maps[map_name].to_dict()
		active_map = map_name
		maps_changed.emit(active_map, maps)
		if debug_log: CustomLogger._log_message(str(self) + " - active map set: " + active_map)
	else:
		if debug_log: CustomLogger._log_message(str(self) + " - active map set failed: " + map_name)

func set_mapping(mapping_name: StringName, mapping: Dictionary[StringName, StringName]) -> void:
	maps[mapping_name] = RequestActionArray.create(mapping)
	maps_changed.emit(active_map, maps)

## {state_name: StringName, {request: StringName, action_name: StringName}}
func set_maps(new_maps: Dictionary[StringName, Dictionary]) -> void:
	for map_name: StringName in new_maps.keys():
		maps[map_name] = RequestActionArray.create(new_maps[map_name])
	maps_changed.emit(active_map, maps)
