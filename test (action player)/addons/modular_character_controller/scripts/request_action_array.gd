extends Resource
class_name RequestActionArray


@export var array: Array[RequestActionPair]


static func create(request_action_map: Dictionary[StringName, StringName]) -> RequestActionArray:
	var result: RequestActionArray = RequestActionArray.new()
	for request: StringName in request_action_map.keys():
		result.array.push_back(RequestActionPair.create(request, request_action_map[request]))
	return result

func _to_string() -> String:
	var result: String = "["
	for action_pair: RequestActionPair in array:
		result += str(action_pair) + ", "
	return result.rstrip(", ") + "]"


func to_dict() -> Dictionary[StringName, StringName]:
	var dict: Dictionary[StringName, StringName] = {}
	for pair: RequestActionPair in array:
		dict[pair.request] = pair.action_name
	return dict
