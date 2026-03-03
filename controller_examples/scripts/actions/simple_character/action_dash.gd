extends ActionNode

## Applies a burst of velocity for a short time on character \
##   forward relative to the direction of its collision shape.
## Uses custom [ActionCollision] to block movement while this action is playing.


const COOLDOWN: float = 0.5
const PLAYTIME: float = 0.25
const SPEED: float = 10.0

@export var _movement_class: MovementState 
@export var _collision_shape_3d: CollisionShape3D

var _cooldown_countdown: float = 0.0
var _playtime_countdown: float = 0.0



func _init() -> void:
	self.TYPE = &"DASH"
	collision = DashCollision.new(self)

func _process(delta: float) -> void:
	if _cooldown_countdown > 0.0:
		_cooldown_countdown -= delta
	
	if _playtime_countdown > 0.0:
		_playtime_countdown -= delta
		
		var forward: Vector3 = -_collision_shape_3d.basis.z
		_movement_class.add_velocity(forward * SPEED, MovementState.Velocity_Tag.MOVE)
		
	elif is_playing:
		super.__exit()


func _can_play() -> bool:
	return _cooldown_countdown <= 0.0

func _enter() -> void:
	_cooldown_countdown = COOLDOWN
	_playtime_countdown = PLAYTIME



class DashCollision extends ActionCollision:
	func collides_with(_other_collision: ActionCollision) -> CollisionType:
		if _other_collision.action_node.TYPE == &"MOVE":
			return CollisionType.BLOCK
		return CollisionType.PASS
