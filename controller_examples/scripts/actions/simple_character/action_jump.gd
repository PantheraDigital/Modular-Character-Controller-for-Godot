extends ActionNode

## Applies upward velocity to character.


const JUMP_STRENGTH: float = 5.0

@export var _movement_class: MovementState 

var _character: CharacterBody3D


func _init() -> void:
	self.TYPE = &"JUMP"


func _can_play() -> bool:
	if _movement_class:
		return _character.is_on_floor() and is_playing == false
	return false

func _play(_params: Dictionary = {}) -> void:
	_movement_class.add_velocity(Vector3.UP * JUMP_STRENGTH, MovementState.Velocity_Tag.JUMP)
	super.__exit()
