extends Node
class_name ActionMap


@export var action_maps: Dictionary[StringName, RequestActionArray] # {state name, {request, action name}}
var _active_map: StringName
var _action_player: ActionPlayer


func _ready() -> void:
	_action_player = get_parent() as ActionPlayer


func set_active_map(map_name: StringName) -> void:
	if !_action_player or !action_maps or map_name == _active_map:
		return
	
	if action_maps.has(map_name):
		_action_player.action_map = action_maps[map_name].to_dict()
		_active_map = map_name

func set_mapping(mapping_name: StringName, mapping: Dictionary[StringName, StringName]) -> void:
	action_maps[mapping_name] = RequestActionArray.create(mapping)
