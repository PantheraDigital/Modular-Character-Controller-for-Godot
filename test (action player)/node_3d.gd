extends Node3D


@export var action_player: ActionPlayer
@export var action_map: ActionMap
@export var action_container: ActionContainer

var node: ActionNode = ActionNode.new()


func _ready() -> void:
	node.name = &"Action3"
	action_player.debug_log = true
	action_container.debug_log = true
	
	call_deferred(&"run_tests", 
	test_play_stop,
	(func():
		print("player map  ", action_player.action_map)
		print("container   ", action_container.action_dict)
	),
	(func():
		self.print_orphan_nodes()
	))

func run_tests(test_stack: Array[Dictionary], pre_test_call: Callable = func():pass, post_test_call: Callable = func():pass):
	printt("-----", "START", "-----")
	var print_bar: bool = false
	for test: Dictionary in test_stack:
		await get_tree().create_timer(0.7).timeout
		print()
		if print_bar:
			print("-----------------------------------------")
		else:
			print_bar = true
		pre_test_call.call()
		print()
		print_rich(test[&"msg"])
		test[&"func"].call()
		print()
		post_test_call.call()
	printt("-----", "DONE", "-----")


var test_new_mapping: Array[Dictionary] = \
[
	{
		&"msg":"[b]add NewMap[/b]",
		&"func":func(): \
			action_map.set_mapping(&"NewMap", {&"Look": &"Action3"}) # no visible change
	},
	{
		&"msg":"[b]set false map active[/b]",
		&"func":func(): \
			action_map.set_active_map(&"Error") # no visible change
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(&"Move") # no visible change
	},
	{
		&"msg":"[b]set NewMap active[/b]",
		&"func":func(): \
			action_map.set_active_map(&"NewMap") # ui shows grey look request
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(&"Move") # no visible change
	},
	{
		&"msg":"[b]add Action3 to container[/b]",
		&"func":func(): \
			action_container.add_child(node) # ui for action bright
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # look request green
	},
	{
		&"msg":"[b]set Flying active[/b]",
		&"func":func(): \
			action_map.set_active_map(&"Flying") # ui shows Flying state requests
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # look request green
	},
]

var test_add_remove_mapping: Array[Dictionary] = \
[
	{
		&"msg":"[b]add action map to Look[/b]",
		&"func":func(): \
			action_player.set_request(&"Look", &"Action3") # action added to ui, ui for action grey
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # no change=
	},
	{
		&"msg":"[b]add Action3 to container[/b]",
		&"func":func(): \
			action_container.add_child(node) # ui for action bright
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # look becomes green=
	},
	{
		&"msg":"[b]remove Action3 from container[/b]",
		&"func":func(): \
			action_container.remove_child(node) # ui for action grey
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # no change
	},
	{
		&"msg":"[b]remove action map from Look[/b]",
		&"func":func(): \
			action_player.set_request(&"Look", &"") # name from ui removed
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # no change
	},
	{
		&"msg":"[b]add Action3 to container[/b]",
		&"func":func(): \
			action_container.add_child(node)
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # no change
	},
	{
		&"msg":"[b]add action map to Look[/b]",
		&"func":func(): \
			action_player.set_request(&"Look", &"Action3") # ui for action bright
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # look becomes green	
	},
]

var test_add_map_add_action: Array[Dictionary] = \
[
	{
		&"msg":"[b]add action map to Look[/b]",
		&"func":func(): \
			action_player.set_request(&"Look", &"Action3") # action added to ui, ui for action grey
	},
	{
		&"msg":"[b]add action map to Look[/b]",
		&"func":func(): \
			action_player.set_request(&"Look", &"Action3") # no change, double add
	},
	{
		&"msg":"[b]add Action3 to container[/b]",
		&"func":func(): \
			action_container.add_child(node) # ui for action bright
	},
	{
		&"msg":"[b]remove Action3 from container[/b]",
		&"func":func(): \
			action_container.remove_child(node) # ui for action grey
	},
	{
		&"msg":"[b]remove action map from Look[/b]",
		&"func":func(): \
			action_player.set_request(&"Look", &"") # name from ui removed
	},
	{
		&"msg":"[b]remove action map from Look[/b]",
		&"func":func(): \
			action_player.set_request(&"Look", &"") # name from ui removed
	},
	{
		&"msg":"[b]add Action3 to container[/b]",
		&"func":func(): \
			action_container.add_child(node)
	},
	{
		&"msg":"[b]add action map to Look[/b]",
		&"func":func(): \
			action_player.set_request(&"Look", &"Action3") # ui for action bright
	},
]

var test_play_stop: Array[Dictionary] = \
[
	{
		&"msg":"[b]play null[/b]",
		&"func":func(): \
			action_player.play(&"BadRequest") # no visible change
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(&"Move") # move request green
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(&"Move") # move request green
	},
	{
		&"msg":"[b]stop Move[/b]",
		&"func":func(): \
			action_player.stop(&"Move") # move request white
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(&"Look") # no visible change (no action connected to request)
	},
]
