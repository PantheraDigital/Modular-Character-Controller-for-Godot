extends Control

## Script for UI to display [ActionPlayer] and [ActionMapRemapper].
##
## Shows actions, and the [ActionNodes] mapped to those actions, in [member ActionPlayer.action_map]
## from [ActionPlayer]. If [ActionMapRemapper] is provided then its maps will be shown too. [br]
## Adding a [NodePath] to a camera node will make it so the UI is only shown to that camera when
## it is [member current].


const PLAYING_COLOR_BG: Color = Color(0.133, 0.55, 0.133, 0.4)
const PLAYING_COLOR_TXT: Color = Color(1,1,1,1)

const ACTIVE_COLOR_BG: Color = Color(0,0,0,0.4)
const ACTIVE_COLOR_TXT: Color = Color(1,1,1,1)
const ACTIVE_COLOR_TXT_PROFILE: Color = Color(0.2,1,1,1)

const INACTIVE_COLOR_BG: Color = Color(0,0,0,0.15)
const INACTIVE_COLOR_TXT: Color = Color(1,1,1,0.6)

@export var action_player: ActionPlayer
@export var action_remapper: ActionMapRemapper
@export_node_path("Camera2D", "Camera3D") var camera_path: NodePath
@export var debug_log: bool

var profile_ui_container: HBoxContainer
var action_ui_container: VBoxContainer

## { ActionNode.name: {"label":Label, "timestamp":int} }
var label_dict: Dictionary[StringName, Dictionary] 

var camera: Node


func _ready() -> void:
	action_ui_container = find_child("ActionContainer")
	profile_ui_container = find_child("ProfileContainer")
	
	if !action_player:
		push_warning(owner, ": ", name, " has no ActionPlayer")
		return
	
	action_player.ready.connect(_late_ready, CONNECT_ONE_SHOT)
	action_player.action_map_changed.connect(_on_action_map_changed)
	action_player.child_entered_tree.connect(_on_action_container_child_entered) 
	action_player.child_exiting_tree.connect(_on_action_container_child_exiting)
	
	if camera_path:
		camera = get_node(camera_path)
		if camera is Camera2D or camera is Camera3D:
			visible = camera.current
		else:
			camera = null
			visible = false
			push_warning(owner, ": ", name, " invalid Camera Node")
	
	if debug_log: CustomLogger._log_message(str(self) + " - READY 1/2")

func _late_ready() -> void:
	_on_action_map_changed(action_player.action_map)
	if debug_log: CustomLogger._log_message(str(self) + " - READY 2/2")

func _process(_delta: float) -> void:
	if !camera:
		return
	
	if camera.current:
		if !visible:
			visible = true
	elif visible:
		visible = false


## Creates a [Label] with a [ColorRect] background.
func _create_label(text: StringName, text_color: Color, background_color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.label_settings = LabelSettings.new()
	label.label_settings.font_color = text_color
	
	var background: ColorRect = ColorRect.new()
	background.color = background_color
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.z_index = -1
	label.add_child(background)
	return label


func _set_label_playing(action: ActionNode) -> void:
	var element: Dictionary = _get_label_by_action(action)
	if !element:
		return
	element[&"label"].label_settings.font_color = PLAYING_COLOR_TXT
	var color_rect: ColorRect = element[&"label"].get_children()[0]
	color_rect.color = PLAYING_COLOR_BG
	element[&"timestamp"] = Time.get_ticks_msec()

func _set_label_not_playing(action: ActionNode) -> void:
	var element: Dictionary = _get_label_by_action(action)
	if !element:
		return
	# delay label change if action play and stop happen too quickly
	# label would always appear off otherwise for actions that start and stop in the same frame
	var set_not_playing: Callable = func():
		if !element or !element[&"label"] or element[&"timestamp"] == -1 or \
			element[&"label"].label_settings.font_color == INACTIVE_COLOR_TXT:
			return
		element[&"timestamp"] = -1
		element[&"timer"] = null
		_set_label_permitted(action)
	
	if Time.get_ticks_msec() - element[&"timestamp"] < 50:
		_set_label_timeout(element[&"request"], set_not_playing) # set repeating timer till "timestamp" is 50msec away from current time
	else:
		set_not_playing.call()

func _set_label_permitted(action: ActionNode) -> void:
	var element: Dictionary = _get_label_by_action(action)
	if !element:
		return
	
	element[&"label"].label_settings.font_color = ACTIVE_COLOR_TXT
	var color_rect: ColorRect = element[&"label"].get_children()[0]
	color_rect.color = ACTIVE_COLOR_BG


# uses a [SceneTreeTimer] to check every interval if callable can be called based on label timestamp
# if timer is up but Time is still too close to timestamp, the timer will be remade
func _set_label_timeout(label_name: StringName, callable: Callable) -> void:
	if label_dict[label_name][&"timer"]:
		return
	
	var element: Dictionary = label_dict[label_name]
	var delay_msec: int = 50 # msec == 1000 sec
	var buffer_play: Callable = func():
		if !label_dict.has(label_name):
			return
		if Time.get_ticks_msec() - element[&"timestamp"] < delay_msec:
			element[&"timer"] = null
			_set_label_timeout(label_name, callable)
		else:
			callable.call()
	
	element[&"timer"] = get_tree().create_timer(delay_msec * 0.001) # msec to sec
	element[&"timer"].timeout.connect(buffer_play)

func _get_label_by_action(action: ActionNode) -> Dictionary:
	for element: Dictionary in label_dict.values():
		if str(element[&"action_path"]) == action.name:
			return element
	return {}


func _clear_chidren(node: Node, free_nodes: bool = false) -> void:
	for node_child: Node in node.get_children():
		node.remove_child(node_child)
		if free_nodes:
			node_child.free()

func _clear_label_dict() -> void:
	var action_container: Dictionary[NodePath, ActionNode] = action_player._action_container
	for element: Dictionary in label_dict.values():
		if !action_container.has(element[&"action_path"]):
			continue
		var action: ActionNode = action_container[element[&"action_path"]]
		if action.enter_action.is_connected(_set_label_playing):
			action.enter_action.disconnect(_set_label_playing)
		if action.exit_action.is_connected(_set_label_not_playing):
			action.exit_action.disconnect(_set_label_not_playing)
	
	label_dict.clear()
 

func _on_action_map_changed(action_map: Dictionary[StringName, NodePath]) -> void:
	if action_remapper:
		_clear_chidren(profile_ui_container, true)
		for map_name: StringName in action_remapper.maps.keys():
			var label: Label = _create_label(map_name, ACTIVE_COLOR_TXT, ACTIVE_COLOR_BG) \
				if action_remapper.active_map == map_name else \
				_create_label(map_name, INACTIVE_COLOR_TXT, INACTIVE_COLOR_BG)
			profile_ui_container.add_child(label)
	
	_clear_chidren(action_ui_container, true)
	_clear_label_dict()
	var action_container: Dictionary[NodePath, ActionNode] = action_player._action_container
	
	# add requests and their actions
	for request: StringName in action_map.keys():
		if label_dict.has(request):
			continue
		
		var action_path: NodePath = action_map[request]
		var action: ActionNode = action_container[action_path] if action_container.has(action_path) else null
		var label: Label = _create_label((request + ": " + str(action_path)), ACTIVE_COLOR_TXT, ACTIVE_COLOR_BG) if action else \
						_create_label((request + ": " + str(action_path)), INACTIVE_COLOR_TXT, INACTIVE_COLOR_BG)
		action_ui_container.add_child(label)
		label_dict[request] = {&"label":label, &"timestamp":Time.get_ticks_msec(), &"timer":null, &"action_path":action_path, &"request":request}
		
		if action and !action.enter_action.is_connected(_set_label_playing):
			action.enter_action.connect(_set_label_playing)
			action.exit_action.connect(_set_label_not_playing)
			if action.is_playing:
				_set_label_playing(action)
	if debug_log: CustomLogger._log_message(str(self) + " - ui refresh: " + str(action_map))


func _on_action_container_child_entered(node:Node) -> void:
	var action: ActionNode = node as ActionNode
	if !action:
		return
	
	var action_path: NodePath = ActionPlayer.name_from_path(action.get_path())
	
	for request: StringName in action_player.action_map.keys():
		if action_player.action_map[request] == action_path:
			label_dict[request][&"action_path"] = action_path
			
			label_dict[request][&"label"].label_settings.font_color = ACTIVE_COLOR_TXT
			var color_rect: ColorRect = label_dict[request][&"label"].get_children()[0]
			color_rect.color = ACTIVE_COLOR_BG
			
			action.enter_action.connect(_set_label_playing)
			action.exit_action.connect(_set_label_not_playing)
			return

func _on_action_container_child_exiting(node:Node) -> void:
	var action: ActionNode = node as ActionNode
	if !action:
		return
	
	var element: Dictionary = _get_label_by_action(action)
	if !element:
		return
	
	element[&"action_path"] = ^""
	element[&"label"].label_settings.font_color = INACTIVE_COLOR_TXT
	var color_rect: ColorRect = element[&"label"].get_children()[0]
	color_rect.color = INACTIVE_COLOR_BG
	
	action.enter_action.disconnect(_set_label_playing)
	action.exit_action.disconnect(_set_label_not_playing)
