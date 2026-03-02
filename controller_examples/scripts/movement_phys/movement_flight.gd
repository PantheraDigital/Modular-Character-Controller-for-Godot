extends MovementState
class_name MovementFlight

## Physics for a character that can move in any direction freely.


var _character: CharacterBody3D 


func _ready() -> void:
	_character = get_parent() \
		if get_parent() is CharacterBody3D else owner \
		if owner is CharacterBody3D else null
	super._ready()

func _physics_process(_delta: float) -> void:
	_character.velocity = input_velocity
	
	_character.move_and_slide()
	clear_input_velocity()
