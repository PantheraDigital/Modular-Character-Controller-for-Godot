extends MovementState
class_name MovementGrounded

## Simple ground based movement physics.

var slow_down_speed: float = 5.0
var _character: CharacterBody3D 


func _ready() -> void:
	_character = get_parent() \
		if get_parent() is CharacterBody3D else owner \
		if owner is CharacterBody3D else null
	super._ready()

func _physics_process(delta: float) -> void:
	if input_velocity:
		var magnitude: float = input_velocity.length()
		if _character.is_on_floor():
			_character.velocity = Vector3(input_velocity.x, _character.velocity.y + input_velocity.y, input_velocity.z)
		else: # accelerate to direction in air instead of snapping to it like when on ground
			_character.velocity.x = move_toward(_character.velocity.x, input_velocity.x, magnitude * slow_down_speed)
			_character.velocity.z = move_toward(_character.velocity.z, input_velocity.z, magnitude * slow_down_speed)
		
	# bring to stop
	elif _character.is_on_floor():
		_character.velocity.x = move_toward(_character.velocity.x, 0.0, slow_down_speed)
		_character.velocity.z = move_toward(_character.velocity.z, 0.0, slow_down_speed)
	
	# add the gravity.
	if !_character.is_on_floor():
		_character.velocity += _character.get_gravity() * delta
	
	# apply velocity 
	if _character.velocity.y < 0:
		_character.apply_floor_snap()
	_character.move_and_slide()
	
	clear_input_velocity()
