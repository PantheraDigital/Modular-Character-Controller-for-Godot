extends Area3D


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("ControllableCharacter"):
		var node: Node = Node.new()
		node.name = "Dash"
		node.set_script(load("res://controller_examples/scripts/simple_character/actions/action_dash.gd"))
		
		var action_container: ActionContainer = body.find_child("ActionContainer", false)
		if action_container:
			action_container.add_child(node)
			get_parent().queue_free()
