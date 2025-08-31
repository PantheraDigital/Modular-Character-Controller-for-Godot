extends ActionNode


const COOLDOWN: float = 0.5
const PLAYTIME: float = 0.25
const SPEED: float = 10.0

var _cooldown_countdown: float = 0.0
var _playtime_countdown: float = 0.0
var _movement_class: MovementState 
var _movement_manager: MovementStateManager

@onready var _character: CharacterBody3D = $"../.."
@onready var _collision_shape_3d: CollisionShape3D = $"../../CollisionShape3D"


func _init() -> void:
	self.ACTION_ID = "DASH"

func _ready() -> void:
	_movement_manager = _character.find_child("MovementManager")
	if !_movement_manager:
		for child in _character.get_children():
			if child is MovementState:
				_movement_class = child
				break

func _process(delta: float) -> void:
	if _cooldown_countdown > 0.0:
		_cooldown_countdown -= delta
	
	if _playtime_countdown > 0.0:
		_playtime_countdown -= delta
		var forward: Vector3 = -_collision_shape_3d.basis.z
		
		if _movement_manager:
			_movement_manager.active_state.move(forward, SPEED)
		else:
			_movement_class.move(forward, SPEED)
	elif is_playing:
		super.stop()


func can_play() -> bool:
	if !is_enabled:
		return false
	if _cooldown_countdown > 0.0:
		return false
	return is_playing == false

func play(_params: Dictionary = {}) -> void:
	_cooldown_countdown = COOLDOWN
	_playtime_countdown = PLAYTIME
	super.play()
