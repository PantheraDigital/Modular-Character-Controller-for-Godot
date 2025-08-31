extends ActionNode

## toggles the character's MovementState and ActionContainer's configuration between flight and grounded movement

@onready var _movement_manager: MovementStateManager = $"../../MovementManager"


func _init() -> void:
	self.ACTION_ID = "TOGGLE_MOVE_STATE"

func can_play() -> bool:
	if !is_enabled or !container._config_profiles:
		return false
	return true

func play(_params: Dictionary = {}) -> void:
	# handle transition to new movement state
	match _movement_manager.active_state.name:
		"GroundedMovement":
			_movement_manager.set_active_state("FlyingMovement")
			container.reconfigure_from_profile("flight")
	
		"FlyingMovement":
			_movement_manager.set_active_state("GroundedMovement")
			container.reconfigure_from_profile("grounded")
	
	super.play()
	await get_tree().process_frame # delay prevents inf loop within controller and action container
	super.stop()
