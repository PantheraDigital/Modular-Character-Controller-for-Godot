extends Resource
class_name RequestActionPair


@export var request: StringName
@export var action_name: StringName


static func create(_request: StringName, _action_name: StringName) -> RequestActionPair:
	var result: RequestActionPair = RequestActionPair.new()
	result.request = _request
	result.action_name = _action_name
	return result

func _to_string() -> String:
	return "(&\"" + request + "\": &\"" + action_name + "\")"
