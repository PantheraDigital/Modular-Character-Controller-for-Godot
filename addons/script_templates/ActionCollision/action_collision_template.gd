# meta-name: Action Collision
# meta-description: Used by ActionManager to determin which ActionNode should play. 
# meta-default: true
extends ActionCollision


func collides_with(_other_collision: ActionCollision) -> CollisionType:
	return CollisionType.PASS

func hit(_other_collision: ActionCollision) -> void:
	_other_collision._hit_by(self)

func _hit_by(_other_collision: ActionCollision) -> void:
	pass
