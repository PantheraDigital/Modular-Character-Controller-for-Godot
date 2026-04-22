extends Node3D


signal key_press

@export var action_player: ActionPlayer
@export var action_remapper: ActionMapRemapper

var node: ActionNode = ActionNode.new()
var node2: ActionNode = ActionNode.new()
var map: Dictionary[StringName, NodePath]


func _ready() -> void:
	node.name = &"Action3"
	node2.name = &"Action4"
	map = {&"Move":^"Move", &"Look":NodePath(), &"Jump":^"Jump", &"Attack":action_player.get_path()}
	
	call_deferred(&"run_tests", 
	test_action_collision,
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

func add_nodes(parent: Node, nodes: Array[Node]) -> void:
	for node:Node in nodes:
		parent.add_child(node)


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
			action_player.set_action_map(self, \
				{&"Move":^"Move", &"Look":NodePath(), &"Jump":node.get_path(), &"Attack":action_player.get_path()})
	},
	{
		# map to same map
		&"msg":"[b]remap to same[/b]",
		&"func":func(): \
			action_player.set_action_map(self, \
				{&"Move":^"Move", &"Look":NodePath(), &"Jump":node.get_path(), &"Attack":action_player.get_path()})
	},
	{
		# empty map
		# map w/ playing actions to empty
		&"msg":"[b]empty map[/b]",
		&"func":func(): \
			action_player.set_action_map(self, {})
	},
	{
		# - stop all playing actions enabled -
		# map w/ duplicate request and path
		# map w/ duplicate request to different path
		&"msg":"[b]remap[/b]",
		&"func":func(): \
			action_player.set_action_map(self, \
				{&"Move":^"Move", &"Look":node.get_path(), &"Jump":NodePath(), &"Attack":NodePath()})
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(self, &"Move")
	},
	{
		# playing action stops
		&"msg":"[b]remap with stop[/b]",
		&"func":func(): \
			action_player.set_action_map(self, \
				{&"Move":^"Move", &"Look":NodePath(), &"Jump":node.get_path(), &"Attack":NodePath()}, true)
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

# setting maps with set_action_map will not edit maps in remapper due to pass by ref 
var test_remapper: Array[Dictionary] = \
[
	{
		&"msg":"[b]change map, bad request[/b]",
		&"func":func(): \
			action_remapper.set_active_map(&"bad")
	},
	{
		&"msg":"[b]set map manual[/b]",
		&"func":func(): \
			action_player.set_action_map(self, \
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

# direct edits change action map in action player but do not trigger action_map_changed signal
# direct edits are also unfiltered allowing for bad paths
var test_external_map_edit: Array[Dictionary] = \
[
	{
		&"msg":"[b]set map[/b]",
		&"func":func(): \
			action_player.set_action_map(self, map)
	},
	{
		&"msg":"[b]edit map[/b]",
		&"func":func(): \
			map[&"Attack"] = ^"BadPath"
	},
	{
		&"msg":"",
		&"func":func(): print(map)
	},
	{
		&"msg":"[b]edit map direct[/b]",
		&"func":func(): \
			action_player.action_map[&"Attack"] = ^"Move"
	},
	{
		&"msg":"",
		&"func":func(): print(map)
	},
]

# direct edits to action map change action remapper maps since they are set by ref
# direct edits will not trigger action_map_changed signal in action_player (debug ui will not update)
var test_external_map_edit_remapper: Array[Dictionary] = \
[
	{
		&"msg":"[b]edit map direct[/b]",
		&"func":func(): \
			action_player.action_map[&"Attack"] = ^"Move"
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

# jump blocks attack
# attack interupts move
# attack should be the only playing action at the end
var test_action_collision: Array[Dictionary] = \
[
	{
		&"msg":"[b]add nodes[/b]",
		&"func":func(): \
			add_nodes(action_player, 
			[ TestAction.new(&"Action3", { &"Attack":^"self" }),
			  TestAction.new(&"Action4", { &"Move":^"Move", &"Look":NodePath(), &"Jump":^"self" }) 
			])
	},
	{
		&"msg":"[b]set map[/b]",
		&"func":func(): \
			action_player.set_action_map(self, 
			{&"Move":^"Move", &"Look":NodePath(), &"Jump":^"Action4", &"Attack":^"Action3"})
	},
	{
		&"msg":"[b]play Move[/b]",
		&"func":func(): \
			action_player.play(self, &"Move")
	},
	{
		&"msg":"[b]play Jump[/b]",
		&"func":func(): \
			action_player.play(self, &"Jump")
	},
	{
		&"msg":"[b]play Attack[/b]",
		&"func":func(): \
			action_player.play(self, &"Attack")
	},
	{
		&"msg":"[b]stop Jump[/b]",
		&"func":func(): \
			action_player.stop(self, &"Jump")
	},
	{
		&"msg":"[b]play Attack[/b]",
		&"func":func(): \
			action_player.play(self, &"Attack")
	},
	{
		&"msg":"result",
		&"func":func(): pass
	},
]

var test_multi_mapping: Array[Dictionary] = \
[
	{
		&"msg":"[b]add node[/b]",
		&"func":func(): \
			action_player.add_child(node)
	},
	{
		&"msg":"[b]set look to node[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Look", node.get_path())
	},
	{
		&"msg":"[b]set move to node[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Move", node.get_path())
	},
	{
		&"msg":"[b]play move[/b]",
		&"func":func(): \
			action_player.play(self, &"Move")
	},
	{
		&"msg":"[b]unset look from node[/b]",
		&"func":func(): \
			action_player.set_request(self, &"Look", ^"")
	},
	{
		&"msg":"[b]set map[/b]",
		&"func":func(): \
			action_player.set_action_map(self, 
			{&"Move":^"Move", &"Look":NodePath(), &"Jump":node.get_path(), &"Attack":node.get_path()})
	},
]

var test_empty_player: Array[Dictionary] = \
[
	{
		&"msg":"[b]add nodes[/b]",
		&"func":func(): \
			add_nodes(action_player, [node, node2])
	},
	{
		&"msg":"[b]set map[/b]",
		&"func":func(): \
			action_player.set_action_map(self, 
			{&"Move":^"Move", &"Look":NodePath(), &"Jump":node2.get_path(), &"Attack":node.get_path()})
	},
	{
		&"msg":"[b]play Jump[/b]",
		&"func":func(): \
			action_player.play(self, &"Jump")
	},
	{
		&"msg":"[b]remove move[/b]",
		&"func":func(): \
			action_player.remove_child(action_player.get_node(^"Move"))
	},
	{
		&"msg":"[b]remove jump[/b]",
		&"func":func(): \
			action_player.remove_child(action_player.get_node(^"Jump"))
	},
	{
		&"msg":"[b]remove action3[/b]",
		&"func":func(): \
			action_player.remove_child(node)
	},
	{
		&"msg":"[b]remove action4[/b]",
		&"func":func(): \
			action_player.remove_child(node2)
	},
	{
		&"msg":"[b]result[/b]",
		&"func":func(): pass
	},
]



class TestAction extends ActionNode:
	var mapping: Dictionary[StringName, NodePath]
	var old_mapping: Dictionary[StringName, NodePath]
	
	func _init(_name: StringName, _mapping: Dictionary[StringName, NodePath]) -> void:
		name = _name
		mapping = _mapping
	
	func _ready() -> void:
		for key: StringName in mapping.keys():
			if mapping[key] == ^"self":
				mapping[key] = self.get_path()
	
	
	func _on_enter() -> void:
		old_mapping = _action_player.action_map
		
		if mapping:
			_action_player.set_action_map(self, mapping)
	
	func _on_exit() -> void:
		if old_mapping:
			_action_player.set_action_map(self, old_mapping)
