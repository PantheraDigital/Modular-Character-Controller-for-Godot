extends MovementState
class_name MovementGroundedSimple



var slow_down_speed: float = 5.0
var _character: CharacterBody3D 


func _ready() -> void:
	if get_parent() is CharacterBody3D:
		_character = get_parent()
	else:
		_character = get_parent().get_parent()
	super._ready()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not _character.is_on_floor():
		_character.velocity += _character.get_gravity() * delta

	if input_direction:
		var input_vector: Vector3 = input_direction * input_magnitude
		_character.velocity = Vector3(input_vector.x, _character.velocity.y, input_vector.z)
	else:
		_character.velocity.x = move_toward(_character.velocity.x, 0, slow_down_speed)
		_character.velocity.z = move_toward(_character.velocity.z, 0, slow_down_speed)

	# Add a force to character
	# useful for jumps
	if impulse_direction != Vector3.ZERO:
		_character.velocity += impulse_direction * impulse_magnitude
		impulse_direction = Vector3.ZERO
		impulse_magnitude = 0.0

	_character.move_and_slide()
