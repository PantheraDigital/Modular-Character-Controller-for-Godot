extends Node
class_name MovementState

## Base class for movement states that handle character physics in that state.

# when force is added from _process()
# tags prevent multiple instances of a force being added in one _phys_process loop
enum Velocity_Tag{
	MOVE = 1 << 0,        # int 1
	JUMP = 1 << 1,        # int 2
	ALT_MOVE = 1 << 2,    # int 4
	
	ALL = MOVE | JUMP | ALT_MOVE
}
var _used_tags: int = 0

@export var enabled: bool = false



var input_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	set_physics_process(enabled)


func enter() -> void:
	enabled = true
	set_physics_process(true)

func exit() -> void:
	clear_input_velocity()
	enabled = false
	set_physics_process(false)

## [param velocity] to add this [method _physics_process] [br]
## [param tag] sets what the velocity is for. If a tag has been used this _physics_process the velocity will not be added. [br]
## This prevents velocity being added twice before it is applied. 
func add_velocity(velocity: Vector3, tag: int) -> void:
	if tag != 0:
		if (_used_tags & tag): # if tag is used
			return
		else: # set tag used
			_used_tags |= tag
	input_velocity += velocity

func clear_input_velocity() -> void:
	input_velocity = Vector3.ZERO
	_used_tags = 0
