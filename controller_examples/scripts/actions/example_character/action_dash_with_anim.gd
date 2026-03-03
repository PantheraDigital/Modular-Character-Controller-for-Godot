extends ActionNode

## Dah action plays animation with rootmotion. 
## Custom [ActionCollision] determins which actions may play or stop 
##   this action while it is playing.
## Collision is set from animation using signals.


var _character: CharacterBody3D

var _collider_is_shrunk: bool 

@export var _movement_class: MovementState
@export var _anim_tree: AnimationTree
@export var _collider_anim_player: AnimationPlayer


func _init() -> void:
	self.TYPE = &"DASH"

func _ready() -> void:
	collision = DashCollision.new(self, _anim_tree)
	
	_anim_tree.animation_finished.connect(
		func(anim_name:StringName):
			if is_playing and anim_name == &"Locomotion/Slide":
				super.__exit()
	)
	
	_collider_anim_player.animation_started.connect(
		func(anim_name:StringName):
			if anim_name == &"shrink":
				_collider_is_shrunk = true
			elif anim_name == &"grow":
				_collider_is_shrunk = false
	)
	


func _can_play() -> bool:
	return !is_playing and _character.is_on_floor()

func _enter() -> void:
	collision.collission_list.clear()

func _play(_params: Dictionary = {}) -> void:
	_anim_tree.play(&"Locomotion/Slide")

func _stop() -> void:
	_anim_tree.fade_out()
	if _collider_is_shrunk:
		_collider_anim_player.play(&"grow")

func _exit() -> void:
	_movement_class.use_root_motion = false



class DashCollision extends ActionCollision:
	var collission_list: Array[StringName]
	
	func _init(owning_action: ActionNode, anim_tree: AnimationTree) -> void:
		super._init(owning_action)
		
		if anim_tree:
			anim_tree.animation_command.connect(_on_animation_command)
	
	func collides_with(_other_collision: ActionCollision) -> CollisionType:
		if _other_collision.action_node.TYPE == &"LOOK":
			return CollisionType.PASS
		if collission_list.has(_other_collision.action_node.TYPE):
			return CollisionType.COLLIDE
		return CollisionType.BLOCK
	
	func _hit_by(_other_collision: ActionCollision) -> void:
		if collission_list.has(_other_collision.action_node.TYPE):
			action_node.stop()
	
	
	func _on_animation_command(animation: StringName, command: StringName) -> void:
		if animation != &"Slide":
			return
		match command:
			&"dash_collision_default":
				collission_list = []
			&"dash_collision_allow_move":
				collission_list.append(&"MOVE")
			&"dash_collision_allow_jump":
				collission_list.append(&"JUMP")
