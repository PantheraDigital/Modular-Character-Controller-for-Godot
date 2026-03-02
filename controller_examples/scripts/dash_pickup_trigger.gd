extends Area3D

## Area trigger that gives characters in the ControllableCharacter group Dash. \
## Character name changes dash type.


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(&"ControllableCharacter"):
		var node: Node = Node.new()
		node.name = &"Dash"
		
		if body.name == &"ExampleCharacter":
			node.set_script(load("res://controller_examples/scripts/actions/example_character/action_dash_with_anim.gd"))
			node._anim_tree = body.find_child("AnimationTree")
			node._collider_anim_player = body.find_child("CollisionShape3D").find_child("AnimationPlayer")
		else:
			node.set_script(load("res://controller_examples/scripts/actions/simple_character/action_dash.gd"))
			node._collision_shape_3d = body.find_child("CollisionShape3D")
		node._movement_class = body.find_child("GroundedMovement")
		
		var action_manager: ActionManager = body.find_child("ActionManager", false)
		if action_manager:
			var added: bool = false
			if action_manager._active_permission_profile:
				added = action_manager._add_action(node, [&"grounded"])
			else:
				added = action_manager._add_action(node)
			
			if added:
				get_parent().queue_free()
