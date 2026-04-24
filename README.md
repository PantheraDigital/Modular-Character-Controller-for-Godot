# Modular-Character-Controller-for-Godot
**Compatible Godot Versions:** 4.4, 4.5, 4.6.1 \
**Contact:** pantheradigitalonline@gmail.com \
**Links:**
- [Itch.io](https://pantheradigital.itch.io/godot-modular-character-controller): Leave a **review**, **play** the demo, read **devlogs**, or _donate_
- [Godot Asset Library](https://godotengine.org/asset-library/asset/4283)
- [Demo Video](https://youtu.be/ABDJnFag9q8)
- [Example Projects](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot-Examples)
<br><br>
[Getting Started](#getting-started) \
| [What Is Included](#what-is-included) \
| [Set Up](#set-up) \
| | [Addon](#addon) \
| | [Examples](#examples) \
[Using the Modular Character Controller](#using-the-modular-character-controller) \
| [General Overview](#general-overview) \
| [Parts](#parts) \
| | [Action Node](#action-node) \
| | [Action Player](#action-player) \
| | [Action Map Remapper](#action-map-remapper) \
| | [Controller](#controller) \
| [Debug](#debug) \
| | [UI](#ui) \
| | [Logger](#logger) 
<br><br>

# Getting Started
## What Is Included
- [core scripts](addons/modular_character_controller/scripts)
  - [debug scripts](addons/modular_character_controller/debug)
- [template scripts](addons/script_templates)
## Set Up
### Addon
1. Download the [addons](addons) folder
2. Place folder in your Godot project
   - If you have an "addons" folder in your project already then bring the [modular_character_controller](addons/modular_character_controller) folder into that folder
   - [Godot installing-a-plugin tutorial](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)
3. Move the [script_templates](addons/script_templates) to your project at the top level directory "res://"
   - If you have a "script_templates" folder, place the contents of this folder into yours.
   - [Godot project-defined-templates tutorial](https://docs.godotengine.org/en/stable/tutorials/scripting/creating_script_templates.html#project-defined-templates)
### Examples
You can find examples I have made using this system [here](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot-Examples).

Each example project contains the version of this project it was made with so some exapmles may not be up to date but will function without additional work.

# Using the Modular Character Controller 
## General Overview 
The heart of Modular Character Controller is two parts, the ActionNode and the ActionPlayer. ActionNodes implement what a character can do and the ActionPlayer is used to tell the character what to do.

This system is designed to make it clear what a character is capable of at any time, while also keeping the character highly modular, making characters faster to develop and easier to adjust at runtime. The character state is no longer a rigid class but a collection of actions that can be changed at any moment.

Input is also separated from the character, following the Model View Controller pattern, by using a request system that allows other objects to request a character perform an action. If they can, and they have that action, then it is done. This allows for much more freedom over what can control a character and makes it easier to tie player inputs to actions.

## Parts
### Action Node
[ActionNodes](addons/modular_character_controller/scripts/action_node.gd) hold the game logic needed for a character to perform a specific task (action) related to the Nodes in the character. Examples would be moving, looking, attacking, climbing, and even taking damage. 

The collection of ActionNodes on a character should represent the different things they may do during game play. However, ActionNodes are designed to be removed and added during gameplay to allow characters to be more dynamic, so all ActionNodes do not need to be attached to the character from the start.

A simple example of a move action would look like this:
```
extends ActionNode


const WALK_FORCE = 600

var _character: CharacterBody2D


func _ready() -> void:
	_character = _action_player.get_parent()


## _params: {"direction": float}
func _on_play(_params: Dictionary = {}) -> void:
	if !_params.has(&"direction"):
		return
	
	# turn input into velocity
	var walk = WALK_FORCE * _params[&"direction"]
	_character.input_velocity.x = walk

func _on_stop() -> void:
	_character.input_velocity.x = 0.0
```
To move call: \
`move_action.play({&"direction":Vector2(1,0)})` \
and to stop: \
`move_action.stop()`

When thinking in terms of a state machine, imagine ActionNodes as the parts of a single state, coming together to make that state. By doing this you can identify shared logic between states that can be a single ActionNode.

### Action Player
The [ActionPlayer](addons/modular_character_controller/scripts/action_player.gd) Plays and Stops actions, and allows for control over which actions are accessible. The way this works is similar to an API by mapping requests to ActionNodes.

This looks like \
`{&"move":^"Move", &"jump":^"Jump"}`, where `&"move"` and `&"jump"` are the requests and `^"Move"` and `^"Jump"` are the ActionNodes attached to the ActionPlayer.

Now to Play an action use \
`action_player.play(self, &"jump")`, this will play the ActionNode that is mapped to the request `&"jump"`.

Similarly, to stop and action use \
`action_player.stop(self, &"jump")`.

To change the actions available, or to change which action is called on by a request, use `set_action_map()` or `set_request()`.

`action_player.set_action_map(self, {&"attack":^"Attack"})` will change the map in ActionPlayer to match what is passed in, if the values are valid. Only ActionNodes that are children of ActionPlayer can be used in the map and they can only be mapped to one request at a time.

`action_player.set_request(self, &"attack", ^"Attack")` will change, or add, a request to the map and follows the same rules as `set_action_map`.

The map can be viewed as the "state" of the character the ActionPlayer is attached to since the map dictates the actions available to the character at a given time.

### Action Map Remapper
The [ActionMapRemapper](addons/modular_character_controller/scripts/action_map_remapper.gd) is simply a tool to manage multiple mappings a character may have. While the ActionPlayer only holds one map, this holds multiple, allowing for easier swapping during gameplay.

The remapper holds maps:
```
{
&"grounded":{&"move":^"Move", &"jump":^"Jump", &"attack":^"Attack"},
&"attacking":{&"attack":^"Attack"}
}
```

The remapper should be added to the ActionPlayer as a child, like an ActionNode, where it can then be used to modify the active mapping like so:
`remapper.set_active_map(&"attacking")`

This will change the map in ActionPlayer to `{&"attack":^"Attack"}` allowing the character to only attack.

This can be done from within ActionNodes, effectively allowing actions to dictate what a character can do while that action is taking place.

### Controller
A [Controller](addons/modular_character_controller/scripts/controller.gd) can be any object that interacts with the ActionPlayer on a character to have it do things, but a generic script is provided as a base.

Controllers may be in the character scene or separate. \
Due to how the ActionPlayer works, a character can have one or many controllers, and a controller may have one or many characters. \
A Controller does not have to be a player controller, it may be an AI controller or even a movement modifier that adds extra movements to a character.

Here is a simple player controller that uses player input to make requests.
```
extends Controller

var run: bool

func _process(_delta: float) -> void:
	var input_direction: Vector2 = Vector2(
		Input.get_axis(&"move_left", &"move_right"),
		Input.get_axis(&"move_up", &"move_down")
	)
	action_player.play(self, &"move", {&"direction":input_direction, &"run":Input.is_action_pressed(&"run")})

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"jump"):
		action_player.play(self, &"jump")
	
	if event.is_action(&"run"):
		run = event.is_action_pressed(&"run")
```

## Debug
### UI
A [UI debugger](addons/modular_character_controller/debug/scenes/action_tree_debug_ui.tscn) is provided. It works with and without ActionMapRemapper. Just add the scene as a child to ActionPlayer. The UI will display all requests, the ActionNodes mapped to those requests, if the action is playing, and the names of the maps ActionMapRemapper adds.

### Logger
ActionPlayer, ActionMapRemapper, and ActionPlayerDebugUI make use of the [CustomLogger](addons/modular_character_controller/debug/scripts/logger.gd) class to print out useful debug info if their debug variable is enabled.

This class is named CustomLogger to prevent problems with the Logger class added in Godot 4.5.
