extends MovementState
class_name MovementGroundedWithAnim

## Extended ground based movement physics to include animations and root motion.

var slow_down_speed: float = 5.0
@export var use_root_motion: bool = false

var _character: CharacterBody3D 
var _anim_tree: AnimationTree
var _collision_shape_3d: CollisionShape3D
var _was_on_floor: bool



func _ready() -> void:
	if get_parent() is CharacterBody3D:
		_character = get_parent()
	else:
		_character = owner
	_anim_tree = _character.find_child("AnimationTree")
	_collision_shape_3d = _character.get_node("CollisionShape3D")
	super._ready()

func _physics_process(delta: float) -> void:
	var was_on_floor: bool = _character.is_on_floor()
	var prev_velocity: Vector3 = _character.velocity
	
	# root motion
	if use_root_motion and _anim_tree and _anim_tree.get_root_motion_position() != Vector3.ZERO:
		var vel: Vector3 = (_anim_tree.get_root_motion_position() / delta).rotated(Vector3.UP, _anim_tree.get_root_motion_rotation().y + _collision_shape_3d.rotation.y)
		_character.velocity = Vector3(-vel.x, _character.velocity.y + vel.y, -vel.z)
		
	# input 
	elif input_velocity:
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
	_character.move_and_slide()
	
	# update animation tree variables
	if _anim_tree:
		_anim_tree.was_on_floor = _was_on_floor
		_anim_tree.is_on_floor = _character.is_on_floor()
		if !was_on_floor and _character.is_on_floor():
			if prev_velocity.normalized().is_equal_approx(Vector3.DOWN):
				_anim_tree.landing_scale = 1 # falling straight down
			elif prev_velocity.length() > 7.0: # arbitrary fall velocity value
				_anim_tree.landing_scale = 2
			elif prev_velocity.length() > 6.0:
				_anim_tree.landing_scale = 1
			else:
				_anim_tree.landing_scale = 0
	
	clear_input_velocity()
