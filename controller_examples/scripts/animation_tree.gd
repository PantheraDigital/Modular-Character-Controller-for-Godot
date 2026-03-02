extends AnimationTree

## Variables and functions for ExampleCharacter's AnimationTree


signal animation_command(animation: StringName, command: StringName)

var is_on_floor: bool
var was_on_floor: bool
var landing_scale: int: # 0-soft, 1-medium, 2-hard
	set(value):
		clamp(value, 0, 2)
		landing_scale = value

var jump: bool:
	set(value):
		jump = value
		if jump:
			get("parameters/StateMachine/playback").travel("Locomotion_Jump")
		self.set(&"parameters/StateMachine/conditions/jump", value)

var idle_to_run_scale: float:
	set(value):
		value = clampf(value, 0.0, 1.0)
		idle_to_run_scale = value
		self.set(&"parameters/StateMachine/BlendSpace1D/blend_position", value)


func play(animation_path: String) -> void:
	get_tree_root().get_node(&"Animation").animation = animation_path
	set(&"parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func fade_out() -> void:
	set(&"parameters/OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FADE_OUT)

func _on_animation_command(animation: StringName, command: StringName) -> void:
	animation_command.emit(animation, command)
