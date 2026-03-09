extends RefCounted
class_name ActionContainer

## Holds [ActionNode]s and allows lookup with either [member ActionNode.TYPE] or [ActionNode]'s [member Node.name].[br]
## Enforces unique [member Node.name] usage.


## Sorted by [member ActionNode.TYPE] then [ActionNode]'s [member Node.name]. [br]
## Example assuming three actions with unique names but two share the same type:[br] 
## [code][type1|name1, type1|name3, type2|name2][/code]
var _actions: Array[ActionNode]


func _to_string() -> String:
	if _actions.is_empty():
		return "[]"
	
	var string: String = "["
	for action in _actions:
		if string.length() == 1:
			string += action.TYPE + "|" + action.name
		else:
			string += ", " + action.TYPE + "|" + action.name
	string += "]"
	return string

## Adds [ActionNode] if its [member Node.name] is not already used by another [ActionNode].
func add_action(action: ActionNode) -> bool:
	if !action:
		return false
	
	var index: int = _get_by_name(action.name)
	if index != -1:
		return false
	
	if "_container" in action:
		action._container = self
	
	_actions.push_back(action)
	_actions.sort_custom(_sort_action)
	return true

## Removes [ActionNode] if it exists.
func remove_action(action: ActionNode) -> bool:
	if !action or _actions.is_empty(): 
		return false
	
	var index: int = _get_by_name(action.name)
	if index == -1:
		return false
	
	if "_container" in action:
		action._container = null
	
	_actions.remove_at(index)
	_actions.sort_custom(_sort_action)
	return true

## Gets [ActionNode]s with the same [member ActionNode.TYPE]. [br]
## The optional [param filter] recives an [ActionNode] and should return [code]true[/code] if the [ActionNode] should be kept, or [code]false[/code] if it should be excluded from the result. [br]
## Example [param filter]:
## [codeblock]
##func (action:ActionNode): return action.name == &"GroundedMove"
## [/codeblock]
func get_actions_by_type(action_type: StringName, filter: Callable = Callable()) -> Array[ActionNode]:
	if _actions.is_empty():
		return []
	
	var index: int = _get_by_type(action_type)
	if index == -1:
		return []
	
	var result: Array[ActionNode] = []
	while index < _actions.size() and _actions[index].TYPE == action_type:
		if filter and !filter.call(_actions[index]):
			index += 1
			continue
		
		result.push_back(_actions[index])
		index += 1
	
	return result

## Find [ActionNode] by [member Node.name].
func get_action_by_name(node_name: StringName) -> ActionNode:
	if _actions.is_empty():
		return null
	var index: int = _get_by_name(node_name)
	return _actions[index] if index != -1 else null

## If [member Node.name] is stored already.
func has_name(node_name: StringName) -> bool:
	if _actions.is_empty():
		return false
	var index: int = _get_by_name(node_name)
	return index != -1

## If any [ActionNode]s in container have [member ActionNode.TYPE] that matches [param action_type].
func has_type(action_type: StringName) -> bool:
	if _actions.is_empty():
		return false
	var index: int = _get_by_type(action_type)
	return _actions[index].TYPE == action_type if index != -1 else false


## [code]true[/code] if the first element should be moved before the second one, otherwise it should return [code]false[/code] [br]
## return a < b
func _sort_action(a: ActionNode, b: ActionNode) -> bool:
	if a.TYPE == b.TYPE:
		return a.name < b.name
	return a.TYPE < b.TYPE

## returns index of matching action or -1 if not found.
func _get_by_name(node_name: StringName) -> int:
	return _actions.find_custom( func(action:ActionNode): return action.name == node_name )

## returns lowest index of matching action or -1 if not found.
func _get_by_type(action_type: StringName) -> int:
	var action: ActionNode = ActionNode.new()
	action.TYPE = action_type
	var index: int = _actions.bsearch_custom(action, _sort_action)
	action.free()
	if index >= _actions.size() or _actions[index].TYPE != action_type:
		index = -1
	while index > 0 and _actions[index - 1].TYPE == action_type:
		index -= 1
	return index
