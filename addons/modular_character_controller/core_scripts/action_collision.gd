extends Resource
class_name ActionCollision

## Used by [ActionManager] when determining which [ActionNode] to play, or which [ActionNode] can play. [br]
## This class handles the interactions [ActionNode]s have with eachother within the [ActionManager].


enum CollisionType
{
	PASS,    ## actions do not hit 
	COLLIDE, ## actions hit eachother
	BLOCK,   ## totally prevent action from happening, hit not called
}

## Owning [ActionNode] of this collider.
var action_node: ActionNode
## [ActionManager] will play the Action with the higher index when two actions are permitted and share [member ActionNode.TYPE]. [br]
## Use if an action should replace another in a configuration without removing the action from [ActionManager] or its permission profile.
var priority_index: int


## Returns the [ActionNode] with the highest priority using [member ActionCollision.priority_index]. [br]
## [ActionNode]s without [ActionCollision] are treated as lowest priority. If no [ActionNode] has [ActionCollision] 
## the last action in [param actions] will be returned.
static func get_action_with_priority(actions: Array[ActionNode]) -> ActionNode:
	var priority_action: ActionNode = null
	for action: ActionNode in actions:
		if !priority_action or !priority_action.collision:
			priority_action = action
			continue
		
		if priority_action.collision and !action.collision:
			continue
		
		if priority_action.collision.priority_index < action.collision.priority_index:
			priority_action = action
	
	return priority_action

## Tests the [ActionCollision] of [param action] against each [ActionCollision] in [param test_actions]. [br]
## Returns the strongest form of [enum ActionCollision.CollisionType] encountered. [br]
## An [ActionNode] with not [ActionCollision] is treated as a [constant PASS]. [br]
## If no collisions [constant BLOCK] the [param action], then all [constant COLLIDE] cases are handled with [code]action.collision.hit(test_action)[/code].
static func handle_collision(action: ActionNode, test_actions: Array[ActionNode]) -> CollisionType:
	if !action.collision:
		return CollisionType.PASS
	
	var collisions: Array[ActionCollision] = []
	for test_action: ActionNode in test_actions:
		if !test_action.collision:
			continue
		
		match test_action.collision.collides_with(action.collision):
			CollisionType.PASS:
				continue
			CollisionType.COLLIDE:
				collisions.push_back(test_action.collision)
			CollisionType.BLOCK:
				return CollisionType.BLOCK
	
	if collisions:
		for collision: ActionCollision in collisions:
			action.collision.hit(collision)
		return CollisionType.COLLIDE
	
	return CollisionType.PASS


func _init(owning_action: ActionNode) -> void:
	action_node = owning_action
	priority_index = 0


## Handles how this action reacts to [param _other_action] colliding with it. [br]
## Called by [method hit] in [ActionManager]. New actions collide with playing actions. [br]
## Useful for when an action should interupt another action before playing.
## 
## [codeblock lang=gdscript]
## # example of JumpAction interrupting currently playing DashAction
## JumpAction.hit(DashAction)
## # in collision for DASH action
## func _hit_by(_other_collision: ActionCollision) -> void:
##     if _other_collision.action_node.TYPE == &"JUMP"
##         action_node.stop()
## [/codeblock]
func _hit_by(_other_collision: ActionCollision) -> void:
	pass

## Gets the [enum CollisionType] between the calling action and [param _other_action].
func collides_with(_other_collision: ActionCollision) -> CollisionType:
	return CollisionType.PASS

## Handles how this action reacts to colliding with [param _other_action]. [br]
## Calls [method _hit_by] on [param _other_action]. [br]
func hit(_other_collision: ActionCollision) -> void:
	_other_collision._hit_by(self)
