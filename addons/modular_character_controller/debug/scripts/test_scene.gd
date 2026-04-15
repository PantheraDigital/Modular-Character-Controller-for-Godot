extends Node3D


signal key_press

@export var action_player: ActionPlayer
@export var action_remapper: ActionMapRemapper

var node: ActionNode = ActionNode.new()


func _ready() -> void:
	node.name = &"Action3"
	
	call_deferred(&"run_tests", 
	test_remapper,
	(func():
		print("player map  ", action_player.action_map)
		print("container   ", action_player._action_container)
		print("playing     ", action_player._playing_actions)
	),
	(func():
		self.print_orphan_nodes()
	))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and event.is_action("ui_accept"):
		key_press.emit()

func run_tests(test_stack: Array[Dictionary], pre_test_call: Callable = func():pass, post_test_call: Callable = func():pass):
	printt("-----", "START", "-----")
	var print_bar: bool = false
	for test: Dictionary in test_stack:
		#await get_tree().create_timer(0.7).timeout
		await key_press
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


var test_play_stop: Array[Dictionary] = \
[
	{
		&"msg":"[b]play null[/b]",
		&"func":func(): \
			action_player.play(self, &"BadRequest") # no visible change
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(self, &"Move") # move request green
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(self, &"Move") # move request green
	},
	{
		&"msg":"[b]stop Move[/b]",
		&"func":func(): \
			action_player.stop(self, &"Move") # move request white
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(self, &"Look") # no visible change (no action connected to request)
	},
]

var test_set_request: Array[Dictionary] = \
[
	{
		&"msg":"[b]set Look to bad path[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Look", action_player.get_path())
	},
	{
		&"msg":"[b]add node[/b]",
		&"func":func(): \
			action_player.add_child(node)
	},
	{
		&"msg":"[b]set Look to node[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Look", node.get_path())
	},
	{
		&"msg":"[b]play Look[/b]",
		&"func":func(): \
			action_player.play(self, &"Look")
	},
	{
		&"msg":"[b]set Look to empty path[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Look", NodePath())
	},
	{
		&"msg":"[b]new request[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Attack", NodePath())
	},
	{
		&"msg":"[b]change request[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Move", node.get_path())
	},
	{
		&"msg":"[b]change request, double node use[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Jump", node.get_path())
	},
	{
		&"msg":"",
		&"func":func(): pass
	},
]

var test_set_action_map: Array[Dictionary] = \
[
	{
		&"msg":"[b]add node[/b]",
		&"func":func(): \
			action_player.add_child(node)
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(self, &"Move")
	},
	{
		# map w/ 1 bad path
		# map w/ duplicate request and path
		# map w/ duplicate request to different path
		# playing action carry over
		&"msg":"[b]remap[/b]",
		&"func":func(): \
			action_player.set_action_map(self, false, \
				{&"Move":^"Move", &"Look":NodePath(), &"Jump":node.get_path(), &"Attack":action_player.get_path()})
	},
	{
		# map to same map
		&"msg":"[b]remap[/b]",
		&"func":func(): \
			action_player.set_action_map(self, false, \
				{&"Move":^"Move", &"Look":NodePath(), &"Jump":node.get_path(), &"Attack":action_player.get_path()})
	},
	{
		# empty map
		# map w/ playing actions to empty
		&"msg":"[b]empty map[/b]",
		&"func":func(): \
			action_player.set_action_map(self, false, {})
	},
	{
		# - stop all playing actions enabled -
		# map w/ duplicate request and path
		# map w/ duplicate request to different path
		&"msg":"[b]remap[/b]",
		&"func":func(): \
			action_player.set_action_map(self, true, \
				{&"Move":^"Move", &"Look":node.get_path(), &"Jump":NodePath(), &"Attack":NodePath()})
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(self, &"Move")
	},
	{
		&"msg":"[b]remap[/b]",
		&"func":func(): \
			action_player.set_action_map(self, true, \
				{&"Move":^"Move", &"Look":NodePath(), &"Jump":node.get_path(), &"Attack":NodePath()})
	},
	{
		&"msg":"[b]remove node[/b]",
		&"func":func(): \
			action_player.remove_child(node)
	},
		{
		&"msg":"",
		&"func":func(): pass
	},
]

var test_remapper: Array[Dictionary] = \
[
	{
		&"msg":"[b]change map, bad request[/b]",
		&"func":func(): \
			action_remapper.set_active_map(&"bad")
	},
	{
		&"msg":"[b]set current map[/b]",
		&"func":func(): \
			action_player.set_action_map(self, false, \
				{&"Move":^"Move", &"Look":NodePath(), &"Jump":^"Jump", &"Attack":action_player.get_path()})
	},
	{
		&"msg":"[b]change map, Air[/b]",
		&"func":func(): \
			action_remapper.set_active_map(&"Air")
	},
	{
		&"msg":"[b]change map, Ground[/b]",
		&"func":func(): \
			action_remapper.set_active_map(&"Ground")
	},
]
