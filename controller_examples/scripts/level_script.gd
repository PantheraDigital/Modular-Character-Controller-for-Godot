extends Node3D

@export var player_controller: Controller
@export var ai_controller: Controller

@export var player_character: Node3D
@export var ai_character: Node3D

var swapped: bool = false


func _process(_delta: float) -> void:
	if Input.is_physical_key_pressed(KEY_ESCAPE):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_TAB:
			if swapped:
				player_controller.controlled_obj = player_character
				ai_controller.controlled_obj = ai_character
				swapped = false
			else:
				player_controller.controlled_obj = ai_character
				ai_controller.controlled_obj = player_character
				swapped = true
