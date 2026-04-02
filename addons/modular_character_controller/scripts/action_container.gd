extends Node
class_name ActionContainer


var action_dict: Dictionary[StringName, ActionNode] # Node.name, Action
var playing_action_names: Array[StringName]
@export var debug_log: bool


func _ready() -> void:
	get_parent().action_map_changed.connect(_on_action_map_changed)
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)
	
	for child: Node in get_children():
		var action: ActionNode = child as ActionNode
		if !action:
			continue
		
		register_action(action)


func set_actions_enabled(action_names: Array[StringName]) -> void:
	for action_name: StringName in action_dict.keys():
		var action: ActionNode = action_dict[action_name]
		
		if action_name in action_names:
			if debug_log: CustomLogger._log_message(str(self) + " - action enabled: " + str(action))
			action.enable()
		else:
			if action.is_playing:
				action.stop()
			
			if debug_log: CustomLogger._log_message(str(self) + " - action disabled: " + str(action))
			action.disable()

func get_playing_actions() -> Array[ActionNode]:
	var result: Array[ActionNode] = []
	for action_name: StringName in playing_action_names:
		result.push_back(action_dict[action_name])
	return result


func register_action(action: ActionNode) -> void:
	if action_dict.has(action.name):
		return
	var action_player: ActionPlayer = get_parent()
	
	if action.is_playing:
		action.stop()
	
	if action_player.action_map.values().has(action.name):
		action.enable()
	
	action_dict[action.name] = action
	action.enter_action.connect(_add_playing_action)
	action.exit_action.connect(_remove_playing_action)
	action.owner = owner
	
	if "_player" in action:
		action._player = action_player
	if "_container" in action:
		action._container = self
	if "_character" in action:
		action._character = action_player.get_parent()
	
	if debug_log: CustomLogger._log_message(str(self) + " - registered action: " + str(action))

func deregister_action(action: ActionNode) -> void:
	if !action_dict.has(action.name):
		return
	
	if action.is_playing:
		action.stop()
	action.disable()
	
	action_dict.erase(action.name)
	action.enter_action.disconnect(_add_playing_action)
	action.exit_action.disconnect(_remove_playing_action)
	action.owner = null
	
	if "_player" in action:
		action._player = null
	if "_container" in action:
		action._container = null
	if "_character" in action:
		action._character = null
	
	if debug_log: CustomLogger._log_message(str(self) + " - deregistered action: " + str(action))


func _add_playing_action(action: ActionNode) -> void:
	if action.is_playing and !playing_action_names.has(action.name):
		playing_action_names.push_back(action.name)
		if debug_log: CustomLogger._log_message(str(self) + " - add playing action: " + str(action))

func _remove_playing_action(action: ActionNode) -> void:
	if !action.is_playing and playing_action_names.has(action.name):
		playing_action_names.remove_at(playing_action_names.find(action.name))
		if debug_log: CustomLogger._log_message(str(self) + " - remove playing action: " + str(action))


func _on_child_entered_tree(node: Node) -> void:
	var action: ActionNode = node as ActionNode
	if !action:
		return
	if debug_log: CustomLogger._log_message(str(self) + " - Action Enter Tree: " + str(action))
	register_action(action)

func _on_child_exiting_tree(node: Node) -> void:
	var action: ActionNode = node as ActionNode
	if !action:
		return
	if debug_log: CustomLogger._log_message(str(self) + " - Action Exit Tree: " + str(action))
	deregister_action(action)

func _on_action_map_changed(action_map: Dictionary[StringName, StringName]) -> void:
	set_actions_enabled(action_map.values())
