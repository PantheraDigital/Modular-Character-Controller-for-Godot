extends MovementState
class_name MovementGroundedComplex



signal step(step_data: Dictionary)
signal climb_ledge(step_data: Dictionary)

const CLIMBABLE_LEDGE: float = 2.3

enum Behavior{
	MOVE = 1 << 0,        # int 1
	STEP = 1 << 1,        # int 2
	ROOT_MOTION = 1 << 2, # int 4
	GRAVITY = 1 << 3,     # int 8
	FLOOR_SNAP = 1 << 4,  # int 16 # reset to true at end of phys process
	IMPLUSE = 1 << 5,     # int 32
	
	ALL = MOVE | STEP | ROOT_MOTION | GRAVITY | FLOOR_SNAP | IMPLUSE
}
var _enabled_movement: int = Behavior.ALL

@export var max_step_up: float = 1.0
@export var max_step_down: float = 1.0

var was_on_floor: bool
var root_motion_override: bool = false

var mass: float = 1.0
var deceleration_rate: float = 5.0
var air_control: float = 0.2 # 0.0 to 1.0 scale of input power when in air. 0 being none and 1 being full control.

var _character: CharacterBody3D
var _collision_shape_3d: CollisionShape3D
var _animation_tree: AnimationTree


func _ready() -> void:
	if get_parent() is CharacterBody3D:
		_character = get_parent()
	else:
		_character = get_parent().get_parent()
	_collision_shape_3d = _character.get_node("CollisionShape3D") # its NOT ok if _collision_shape_3d is null
	_animation_tree = _character.find_child("AnimationTree", false) # its ok if _animation_tree is null
	super._ready()

func _physics_process(delta: float) -> void:
	was_on_floor = _character.is_on_floor() # save state before moving the character
	
	_process_velocity(delta)
	
	# ledge step up correction
	var stepped_up: bool = false
	if is_movement_enabled(Behavior.STEP) and (!input_direction.is_zero_approx() or root_motion_override):
		stepped_up = _step_up_correction()
	
	_character.move_and_slide()
	
	# ledge step down correction
	if is_movement_enabled(Behavior.STEP) and !stepped_up and !_character.is_on_floor() and _character.velocity.y <= 0 and was_on_floor:
		var ground_validation: Callable = func(_point: Vector3, _normal: Vector3) -> bool : return _normal.angle_to(Vector3.UP) <= _character.floor_max_angle
		var step_data: Dictionary = CharacterStep3D.step_down(_character.get_rid(), _character.global_transform, max_step_down, Vector3(_character.velocity.x, 0.0, _character.velocity.z).normalized(), _collision_shape_3d.shape.radius, ground_validation)
		if !step_data.is_empty():
			_character.global_position = step_data["point"]
	
	if is_movement_enabled(Behavior.FLOOR_SNAP):
		_character.apply_floor_snap()
	else:
		enable_movement(Behavior.FLOOR_SNAP)


#region Movement Modification
# https://mplnet.gsfc.nasa.gov/about-flags
func disable_all_movement() -> void:
	disable_movement(Behavior.ALL)

func enable_all_movement() -> void:
	enable_movement(Behavior.ALL)

# example inputs:
# enabled_movement(Behavior.MOVE) # enable move
# enabled_movement(Behavior.MOVE | Behavior.IMPULSE) # enable move and impulse
func enable_movement(actions: int) -> void:
	_enabled_movement |= actions

# example inputs:
# disable_movement(Behavior.MOVE) # disable only move
# disable_movement(Behavior.MOVE | Behavior.IMPULSE) # disable move and impulse
func disable_movement(actions: int) -> void:
	_enabled_movement &= ~actions

func is_movement_enabled(movement_type: Behavior) -> bool:
	return (_enabled_movement & movement_type)
#endregion


#region Private Methods
func _process_velocity(delta: float) -> void:
	# handle root motion if detected 
	root_motion_override = false
	if _animation_tree and is_movement_enabled(Behavior.ROOT_MOTION) and _animation_tree.get_root_motion_position() != Vector3.ZERO:
		var vel: Vector3 = (_animation_tree.get_root_motion_position() / delta).rotated(Vector3.UP, _animation_tree.get_root_motion_rotation().y + _collision_shape_3d.rotation.y)
		if is_movement_enabled(Behavior.GRAVITY):
			_character.velocity = Vector3(-vel.x, _character.velocity.y, -vel.z)
		else:
			_character.velocity = Vector3(-vel.x, vel.y, -vel.z)
		
		if _character.velocity.y > 0:
			disable_movement(Behavior.FLOOR_SNAP)
		root_motion_override = true
		
	# handle input for velocity over time
	elif is_movement_enabled(Behavior.MOVE):
		if input_direction:
			var input_vector: Vector3 = input_direction * input_magnitude
			if _character.is_on_floor():
				_character.velocity = Vector3(input_vector.x, _character.velocity.y, input_vector.z)
			else: # accelerate to direction in air instead of snapping to it like when on ground
				_character.velocity.x = move_toward(_character.velocity.x, input_vector.x, input_magnitude * air_control)
				_character.velocity.z = move_toward(_character.velocity.z, input_vector.z, input_magnitude * air_control)
		elif _character.is_on_floor():
			_character.velocity.x = move_toward(_character.velocity.x, 0, deceleration_rate)
			_character.velocity.z = move_toward(_character.velocity.z, 0, deceleration_rate)
	
	# handle impulse input
	if is_movement_enabled(Behavior.IMPLUSE) and impulse_direction != Vector3.ZERO:
		_character.velocity += impulse_direction * impulse_magnitude
		impulse_direction = Vector3.ZERO
		impulse_magnitude = 0.0
		disable_movement(Behavior.FLOOR_SNAP)
	
	# add gravity
	if is_movement_enabled(Behavior.GRAVITY):
		_character.velocity += (_character.get_gravity() * mass) * delta


func _step_up_correction() -> bool:
	var ledge_result: Dictionary = _tripple_snapped_ray(_character.global_position, Vector3(_character.velocity.x, 0.0, _character.velocity.z).normalized(), _collision_shape_3d.shape.radius + 0.1, _collision_shape_3d.shape.radius * 0.5)
	if ledge_result.is_empty() and _character.get_floor_normal().angle_to(Vector3.UP) > _character.floor_max_angle:
		return false
	
	var stepped_up: bool = false
	var step_data: Dictionary = CharacterStep3D.step_up(_character.get_rid(), _character.global_transform, CLIMBABLE_LEDGE, Vector3(_character.velocity.x, 0.0, _character.velocity.z).normalized(), _collision_shape_3d.shape.radius * 0.5, 0.15)
	if step_data.is_empty() or step_data["normal"].angle_to(Vector3.UP) > _character.floor_max_angle:
		return false
	
	var step_height: float = step_data["point"].y - _character.global_position.y
	var result_data: Dictionary = \
		{"step_point":step_data["point"], "step_normal":step_data["normal"], "ray_cast_point":ledge_result["position"], "ray_cast_normal":ledge_result["normal"]} \
		if ledge_result.has("normal") else \
		{"step_point":step_data["point"], "step_normal":step_data["normal"]}
		
	# float is an arbitrary number I chose to allow a small range in height for this climb anim
	if (CLIMBABLE_LEDGE - 0.04) <= step_height and step_height <= CLIMBABLE_LEDGE:
		stepped_up = true
		climb_ledge.emit(result_data)
	if step_height <= max_step_up:
		_character.global_position.y = step_data["point"].y
		stepped_up = true
		step.emit(result_data)
	
	return stepped_up

func _tripple_snapped_ray(start: Vector3, direction: Vector3, length: float, gap: float) -> Variant:
	var found_ledge: bool = false
	# set up variables for ledge detection
	var start_offset: Vector3 = Vector3.ZERO
	var hit_result: Dictionary = {}
	
	for i in range(3):
		if i == 1: # offset left
			start_offset = ((direction.rotated(Vector3.UP, deg_to_rad(90))).normalized() * gap)
		elif i == 2: # offset right
			start_offset = ((direction.rotated(Vector3.UP, deg_to_rad(-90))).normalized() * gap)
			
		hit_result = CharacterStep3D.snapped_intersect_ray(_character.get_world_3d().direct_space_state, start + start_offset, direction, length, false, [_character])
		if hit_result.has("normal"):
			found_ledge = hit_result.normal.angle_to(Vector3.UP) > _character.floor_max_angle
		
		if found_ledge:
			break
	
	return hit_result

#endregion
