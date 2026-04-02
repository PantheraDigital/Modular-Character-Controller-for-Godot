@tool
extends Node
class_name ActionPlayer


signal action_map_changed(action_map: Dictionary[StringName, StringName])

@export var action_map: Dictionary[StringName, StringName]: # Request, Action Node.name
	set(value):
		if stop_all_actions_on_full_remap:
			for action_name: StringName in _action_container.playing_action_names:
				_action_container.action_dict[action_name].stop()
		
		action_map = value
		action_map_changed.emit(action_map)

@export var stop_all_actions_on_full_remap: bool
@export var debug_log: bool

var _action_container: ActionContainer


func _ready() -> void:
	_action_container = find_child("ActionContainer", false)
	if !_action_container:
		_action_container = ActionContainer.new()
		_action_container.name = &"ActionContainer"
		
		add_child(_action_container)
		_action_container.owner = get_tree().edited_scene_root if get_tree() and get_tree().edited_scene_root else self
		return
	
	if Engine.is_editor_hint():
		return
	
	_action_container.set_actions_enabled(action_map.values())


func play(request: StringName, params: Dictionary = {}) -> void:
	if Engine.is_editor_hint():
		return
	if !action_map.has(request):
		if debug_log: CustomLogger._log_message(str(self) + " - (Play) No such request: " + request)
		return
	
	var action_name: StringName = action_map[request]
	if action_name and _action_container.action_dict.has(action_name):
		var played: bool = _action_container.action_dict[action_name].play(get_context(), params)
		
		if debug_log:
			if played:
				CustomLogger._log_message(str(self) + " - Play: " + action_name + " from request " + request)
			else:
				CustomLogger._log_message(str(self) + " - Play Failed: " + action_name + " from request " + request)
	elif debug_log:
		CustomLogger._log_message(str(self) + " - (Play) No mapped Action to request: " + request)

func stop(request: StringName) -> void:
	if Engine.is_editor_hint():
		return
	if !action_map.has(request):
		if debug_log: CustomLogger._log_message(str(self) + " - (Stop) No such request: " + request)
		return
	
	var action_name: StringName = action_map[request]
	if action_name and _action_container.action_dict.has(action_name):
		var stopped: bool = _action_container.action_dict[action_name].stop()
		
		if debug_log:
			if stopped:
				CustomLogger._log_message(str(self) + " - Stop: " + action_name + " from request " + request)
			else:
				CustomLogger._log_message(str(self) + " - Stop Failed: " + action_name + " from request " + request)
	elif debug_log:
		CustomLogger._log_message(str(self) + " - (Stop) No mapped Action to request: " + request)


func set_request(request: StringName, action_name: StringName) -> void:
	if Engine.is_editor_hint():
		return
	action_map[request] = action_name
	action_map_changed.emit(action_map)


func get_context() -> Dictionary[StringName, Variant]:
	if Engine.is_editor_hint():
		return {&"playing_action_names":[],
				&"action_map":[]}
	
	return {&"playing_action_names": _action_container.playing_action_names,
			&"action_map": action_map.duplicate()}

func get_requests() -> Array[StringName]:
	if Engine.is_editor_hint():
		return []
	return action_map.keys()

func get_actions() -> Array[StringName]:
	if Engine.is_editor_hint():
		return []
	return action_map.values().filter(func(action_name: StringName): return !action_name.is_empty())
