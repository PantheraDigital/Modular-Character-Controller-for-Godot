extends Control

## UI for showing action states on a character. Displays all actions and permission profiles. Shows which actions can play, are playing, and which are blocked. [br]
## Updates when [signal ActionManager.managed_actions_change] emits. [br]
## MUST be a child of [ActionManager].

const PLAYING_COLOR_BG: Color = Color(0.133, 0.55, 0.133, 0.4)
const PLAYING_COLOR_TXT: Color = Color(1,1,1,1)

const ACTIVE_COLOR_BG: Color = Color(0,0,0,0.4)
const ACTIVE_COLOR_TXT: Color = Color(1,1,1,1)
const ACTIVE_COLOR_TXT_PROFILE: Color = Color(0.2,1,1,1)

const INACTIVE_COLOR_BG: Color = Color(0,0,0,0.15)
const INACTIVE_COLOR_TXT: Color = Color(1,1,1,0.6)


var camera: Camera3D
var profile_ui_container: HBoxContainer
var action_ui_container: VBoxContainer
## { ActionNode.name: {"label":Label, "timestamp":int} }
var label_dict: Dictionary[StringName, Dictionary] 


func _ready() -> void:
	action_ui_container = find_child("ActionContainer")
	profile_ui_container = find_child("ProfileContainer")
	camera = owner.find_child("Camera3D")
	if !camera:
		var children: Array[Node] = owner.find_children("*", "Camera3D")
		if children:
			camera = children[0]
	
	if camera and camera.current and visible:
		visible = false
	
	_update_ui()
	
	var action_manager: ActionManager = get_parent()
	action_manager.managed_actions_change.connect(_on_managed_actions_change)

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

## Updates UI to match state of actions in [ActionManager]. Adds new [Label]s when needed using [method _create_label], otherwise updates colors using _set_label functions.
func _update_ui() -> void:
	var action_manager: ActionManager = get_parent()
	var permitted_actions: Array[StringName] = []
	if action_manager._action_permissions and action_manager._action_permissions.is_valid():
		permitted_actions = action_manager._action_permissions.get_permissions(action_manager._active_permission_profile)
	
	var all_actions: Array[ActionNode] = action_manager._action_container._actions
	var buffer: Array[Control] = []
	
	# add profile label
	if action_manager._action_permissions and action_manager._action_permissions.is_valid():
		_clear_chidren(profile_ui_container)
		
		var prof_name: StringName = "prof-" + action_manager._active_permission_profile
		# active profile
		if !label_dict.has(prof_name):
			var profile_ui: Label = _create_label(prof_name, ACTIVE_COLOR_TXT_PROFILE, ACTIVE_COLOR_BG)
			label_dict[prof_name] = {"label":profile_ui, "timestamp":-1}
			label_dict[prof_name]["label"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
		profile_ui_container.add_child(label_dict[prof_name]["label"])
		_set_profile_active(prof_name)
		
		# inactive profiles
		for permission_profile: StringName in action_manager._action_permissions._profiles.keys():
			if permission_profile == action_manager._active_permission_profile:
				continue
			prof_name = "prof-" + permission_profile
			if !label_dict.has(prof_name):
				var profile_ui: Label = _create_label(prof_name, INACTIVE_COLOR_TXT, INACTIVE_COLOR_BG)
				label_dict[prof_name] = {"label":profile_ui, "timestamp":-1}
				label_dict[prof_name]["label"].size_flags_horizontal = Control.SIZE_EXPAND_FILL
			profile_ui_container.add_child(label_dict[prof_name]["label"])
			_set_profile_inactive(prof_name)
	
	# fill tree with actions
	for action: ActionNode in all_actions:
		if action_manager._action_permissions and action_manager._action_permissions.is_valid() and !action_manager._action_permissions.has_name(action.name):
			continue # filter out private actions
		
		var permitted: bool = (action.name in permitted_actions) if !permitted_actions.is_empty() else true
		
		# add missing action
		if !label_dict.has(action.name):
			var action_ui: Label = _create_label(action.name, (ACTIVE_COLOR_TXT if permitted else INACTIVE_COLOR_TXT), (ACTIVE_COLOR_BG if permitted else INACTIVE_COLOR_BG))
			action.play_action.connect(_set_label_playing)
			action.exit_action.connect(_set_label_not_playing)
			label_dict[action.name] = {"label":action_ui, "timestamp":-1}
		
		if permitted:
			action_ui_container.add_child(label_dict[action.name]["label"])
			if action.is_playing:
				_set_label_playing(action)
			else:
				_set_label_permitted(action)
		else:
			buffer.append(label_dict[action.name]["label"])
			_set_label_prohibited(action)
	
	for control: Control in buffer:
		action_ui_container.add_child(control)


func _set_label_playing(action: ActionNode) -> void:
	label_dict[action.name]["label"].label_settings.font_color = PLAYING_COLOR_TXT
	var color_rect: ColorRect = label_dict[action.name]["label"].get_children()[0]
	color_rect.color = PLAYING_COLOR_BG
	label_dict[action.name]["timestamp"] = Time.get_ticks_msec()

func _set_label_not_playing(action: ActionNode) -> void:
	# delay label change if action play and stop happen too quickly
	# label would always appear off otherwise for actions that start and stop in the same frame
	while Time.get_ticks_msec() - label_dict[action.name]["timestamp"] < 50:
		await get_tree().process_frame
	if label_dict[action.name]["label"].label_settings.font_color == INACTIVE_COLOR_TXT:
		return
	label_dict[action.name]["timestamp"] = -1
	_set_label_permitted(action)

func _set_label_permitted(action: ActionNode) -> void:
	label_dict[action.name]["label"].label_settings.font_color = ACTIVE_COLOR_TXT
	var color_rect: ColorRect = label_dict[action.name]["label"].get_children()[0]
	color_rect.color = ACTIVE_COLOR_BG

func _set_label_prohibited(action: ActionNode) -> void:
	label_dict[action.name]["label"].label_settings.font_color = INACTIVE_COLOR_TXT
	var color_rect: ColorRect = label_dict[action.name]["label"].get_children()[0]
	color_rect.color = INACTIVE_COLOR_BG

func _set_profile_inactive(profile_name: StringName) -> void:
	if !label_dict.has(profile_name):
		return
	label_dict[profile_name]["label"].label_settings.font_color = INACTIVE_COLOR_TXT
	var color_rect: ColorRect = label_dict[profile_name]["label"].get_children()[0]
	color_rect.color = INACTIVE_COLOR_BG

func _set_profile_active(profile_name: StringName) -> void:
	if !label_dict.has(profile_name):
		return
	label_dict[profile_name]["label"].label_settings.font_color = ACTIVE_COLOR_TXT_PROFILE
	var color_rect: ColorRect = label_dict[profile_name]["label"].get_children()[0]
	color_rect.color = ACTIVE_COLOR_BG


func _clear_chidren(node: Node) -> void:
	for node_child: Node in node.get_children():
		node.remove_child(node_child)

func _on_managed_actions_change(_active_profile: StringName, _permitted_actions: Array[StringName]) -> void:
	_clear_chidren(action_ui_container)
	_update_ui()
