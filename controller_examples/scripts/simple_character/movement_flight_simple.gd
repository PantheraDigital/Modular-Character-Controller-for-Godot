extends MovementState
class_name MovementFlightSimple



var _character: CharacterBody3D 


func _ready() -> void:
	if get_parent() is CharacterBody3D:
		_character = get_parent()
	else:
		_character = get_parent().get_parent()
	super._ready()

func _physics_process(_delta: float) -> void:
	_character.velocity = input_direction * input_magnitude
	
	if impulse_direction != Vector3.ZERO:
		_character.velocity += impulse_direction * impulse_magnitude
		impulse_direction = Vector3.ZERO
		impulse_magnitude = 0.0
	
	_character.move_and_slide()
