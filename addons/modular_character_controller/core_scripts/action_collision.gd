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
