# Modular-Character-Controller-for-Godot
**Contact:** pantheradigitalonline@gmail.com 

Leave a **review**, **play** the demo level in browser, read **devlogs**, or _donate_: [Itch.io](https://pantheradigital.itch.io/godot-modular-character-controller) 

[Demo Video](https://youtu.be/ABDJnFag9q8) 

<br/><br/>
**_Update Notes_** \
Latest version of this system not compatible with older version. Major restructuring and name changes. \
Tested on Godot versions 4.4, 4.5, 4.6.1
<br/><br/>

[About](#about) \
[Why This Exists](#why-this-exists) \
[Getting Started](#getting-started) \
| [What Is Included](#what-is-included) \
| [Set Up](#set-up) \
| | [Addon/Plugin](#addonplugin) \
| | [As a Project](#as-a-project) \
[Using the Action System](#using-the-action-system) \
| [Parts](#parts) \
| | [Action Node](#action-node) \
| | [Action Collision](#action-collision) \
| | [Action Manager](#action-manager) \
| | [Action Container](#action-container) \
| | [Permission Container](#permission-container) \
| | [Controller](#controller) \
| [Structure](#structure) \
| [Implementing](#implementing) \
| [Debug](#debug)


# About
The Modular Character Controller is a set of scripts that aims to make the creation of controllable objects in Godot more organized and flexible. Controllable object examples would be the player character, AI controlled NPCs, and vehicles. Organization and flexibility are achieved by separating logic out into components for the character to prevent a monolithic character script that attempts to handle all logic, physics, and animation in one place. This separation of logic into single task focused pieces makes code more organized but also allows pieces of logic to be attached and detached from a character, making characters modular at runtime.

## Why This Exists
While learning Godot and building my first character I was following tutorials and the examples Godot provides, such as the CharacterBody3D Basic Movement template script. While doing so I noticed my character script growing in complexity, which I did not like as it was difficult to add or remove functionality as the character grew past basic functionality. I realized having a character script is a trap and leads to a monolithic class, so, after some planning, I broke everything down and came up with this system. Now a character script is not needed and its easier to make, and experiment with, more complex characters.

I decided against using states for the same reasons I feel a character script is a trap. With states you would need many specific states that would lead to repeating code or management issues in cases where two or more states are valid, or you would need few broad states which just creates monoliths but a little smaller. Character are more fluid and may have actions come and go (upgrades that change how an action works or weapons that change attacks). To handle this states would defer the logic of these changing actions, so I took it a step further and got rid of states, allowing actions to be dynamically managed at runtime. The state is no longer a set class but rather a composite of actions that can play.


# Getting Started
## What Is Included
- [core scripts](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/tree/main/modular_character_controller/core_scripts)
  - [debug scripts](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/tree/main/modular_character_controller/debug)
- [template scripts](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/tree/main/script_templates)
- two example characters
  - [simple](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scenes/SimpleCharacter.tscn) : This displays the Godot CharacterBody3D Basic Movement template adapted to this system.
  - [example](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scenes/ExampleCharacter.tscn) : An animated character using more of the features this system provides (a closer representation of the average playable character).
- [demo level](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scenes/Level.tscn) : A scene with both characters set up to allow the player to swap between them.
- [action pickup](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scenes/DashPickup.tscn) : An example of an object adding an action to a character at runtime.

## Set Up
### Addon/Plugin
1. Move the [modular_character_controller](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/tree/main/modular_character_controller) folder to your "addons" folder.
   - Create an "addons" folder in the "res://" directory if you have not already. [Godot installing-a-plugin tutorial](https://docs.godotengine.org/en/stable/tutorials/plugins/editor/installing_plugins.html#installing-a-plugin)
2. Move the [script_templates](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/tree/main/script_templates) to your project [Godot project-defined-templates tutorial](https://docs.godotengine.org/en/stable/tutorials/scripting/creating_script_templates.html#project-defined-templates)
   - If you do not have a "script_templates" folder in your project already, just drop this folder in the "res://" directory of your project.
   - If you have a "script_templates" folder, place the contents of this folder into yours.

### As a Project
1. Download
2. Extract/unzip
   - Place extracted project where you keep your projects.
3. Open with Godot
   - Select the scan button at the top of the Godot Project Manager to find the project.


# Using the Action System 

## Parts
_In the example characters I make use of [movement_state](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scripts/movement_phys/movement_state.gd) and [movement_state_manager](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scripts/movement_phys/movement_state_manager.gd). These are not critical to this system. They are how I separated the physics from the actions so multiple actions can interact with the physics. Because of this I will not discuss them here. You can chose to use them or your own implementation of physics handling._

### Action Node
[action_node](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/core_scripts/action_node.gd)s hold all the logic for your character to perform a single action. These are used to build the functionality of your characters. They are simply told to play, then they perform their logic and determine when they are done playing. Fire and forget.

See the script for details about the functions and signals available.

The simplest example of an action node would be the jump action used in the simple example character [action_jump](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scripts/actions/simple_character/action_jump.gd)

A core part of how action nodes are used is that they have a type defined by a string name. This type is how actions are called to play. Using the jump action as an example, it has a type of "jump" which ties into the input used that it responds to. A controller will call for the jump action to play, then an action that matches that type will be found then played. 

This is used instead of class names so that multiple actions can respond to the same type call, but keep in mind only one action will actually play per call. See Action Manager for more.

### Action Collision
Many actions may be playing at once and they may have interactions with each other when a new one tries to play, such as an action blocking another from playing or interrupting an action currently playing, this is what [action_collision](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/core_scripts/action_collision.gd) is for.

Thinking of actions as objects for a moment, for an action to play it must move through all the actions that are currently playing. Some actions may not collide, allowing the action to freely move through and play, but some actions may collide with others where some kind of interaction may take place.

<img width="424" height="424" alt="ActionCollisionDiagram" src="https://github.com/user-attachments/assets/d0159d29-20ea-4718-b9ca-f5637c6c600f" />

See the [action_dash](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scripts/actions/simple_character/action_dash.gd) and [complex action dash](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scripts/actions/example_character/action_dash_with_anim.gd) for examples of action collision.

### Action Manager
The [action_manager](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/core_scripts/action_manager.gd) acts as the connection point between the controller and character. This is where the controller requests the character play or stop an action. "Request" is a key word here since the action may not exist or be able to play/stop.

Only one action is selected to play per request. When choosing an action to play, they are first filtered by permission profile, if one exists, then collision. If none of these are set and there are multiple actions with the same type, then the first found matching action will play. 

Having only one action respond to a request prevents possible overlapping logic issues.

While only one action responds to a request, multiple actions may still be playing at a time since the life time of an action playing is up to the action.

### Action Container
[action_container](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/core_scripts/action_container.gd)s hold the actions attached to the action manager in a sorted array so that actions can be found using either their node name or by their action type. Because of this unique node names are enforced across all actions attached to one character.

This is done this way so actions can be found by their type when a play request happens but also so a specific action node can be found using their node name. Node names are used internally (within the action system) when seeking a specific node.

### Permission Container
Sometimes it is desired to limit which actions can play based on the character's state, or other reason. For this permission profiles can be used, which are held in a [permission container](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/core_scripts/permission_container.gd) by action manager.

A simple set of permission profiles may look like this:
```
{
  "grounded" : ["Move","Jump"],
  "flying"   : ["Move","Ascend","Descend"]
} 
```
If the character has the "grounded" profile active it may only play the move and jump action, but if the "flying" profile is active then it can move, ascend, and descend. In this example all the actions are on the character at the same time, but to prevent the character from ascending or descending when grounded profiles are used to limit available actions. See the [ExampleCharacter](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scenes/ExampleCharacter.tscn)'s action manager for an example of this.

These profile may be controlled and set from the action manager. Here is an example of how that may look if an action were to change the active profile. This jump action changes the character from grounded to flying if the controller performs a double jump. [action_jump_with_transition](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scripts/actions/example_character/action_jump_with_transition.gd)

### Controller
The [controller](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/core_scripts/controller.gd) is a class that interacts with the action manager to have a character perform actions. The controller may be attached to the character or separate. This is where player input would be handled or AI logic.

While this class is important to the structure of the action system, this exact class is not required. You may implement your own controller without extending this class.

## Structure
This system follows a 3 part structure. \
_Controller -> Action Manager -> Action_ \
Controller: requests an action to play \
Action Manager: attempts to find and play the action \
Action: performs logic 

In engine it looks like this:

<img width="262" height="590" alt="CharacterNodes" src="https://github.com/user-attachments/assets/198ea71e-c70d-4626-ac6e-53995b0eccd6" />
<img width="262" height="590" alt="LevelNodes" src="https://github.com/user-attachments/assets/5779d960-43cb-4eee-b928-fb1613566097" />

The controller is connected to the character's Action Manager (it may be in the character scene or anywhere else). The Action Manager is a node on the character. Actions are attached to the Action Manager, creating an action tree.

In more complex characters the action tree may be used to indicate permission profiles.

<img width="287" height="543" alt="ComplexCharacterTree" src="https://github.com/user-attachments/assets/1c8399e9-96cf-4d86-8a26-bde23b59f4bb" />
<img width="451" height="820" alt="ComplexCharacterProfiles" src="https://github.com/user-attachments/assets/ffef5de8-1fd7-4730-9581-874c4355dea3" />

See [action_manager_permission_tool](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/debug/scripts/action_manager_permission_tool.gd) for details on this structure and how its used.

Comparing this to a state based system, you can think of character states as groups of actions. I refer to this as the characters "configuration" at times in the scripts. If your character will have multiple "states", the easiest way to define these is using the permission profiles.

## Implementing 
Although there are a lot of parts, the minimum you need to code is a controller and an action extended from [action_node](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/core_scripts/action_node.gd). Use the controller to take input and ask the action manager to play the action that you created. 

For more complex characters you may need to use profile permissions and action collisions to manage what actions can play. See the [ExampleCharacter](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scenes/ExampleCharacter.tscn) for an example using the permission profiles and the [action_dash](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/controller_examples/scripts/actions/simple_character/action_dash.gd) for an example of collision.

## Debug
There are two included ways to help with debugging, the [custom_logger](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/debug/scripts/logger.gd) used in action manager and the [action_tree_debug_ui](https://github.com/PantheraDigital/Modular-Character-Controller-for-Godot/blob/main/modular_character_controller/debug/scripts/action_tree_debug_ui.gd).

The logger gives details on the manager during its setup phase and details on action play requests such as collision or if the action does not exist. This is useful for detailed info on the system, just check the log variable in the inspector of an action manager.

<img width="1267" height="469" alt="Screenshot from 2026-03-05 01-46-42" src="https://github.com/user-attachments/assets/63cd9568-c2f8-4f30-b74a-5c0e8322095d" />

The UI is a scene that will display all actions the manager has access to. It will show which actions can play, are playing, and which can't be played. It will also show the permission profiles and which is active. This is helpful for evaluating complex characters and their actions, as well as ensuring actions are playing properly. Add the scene to any action manager.

<img width="1164" height="660" alt="Screenshot from 2026-03-05 01-48-03" src="https://github.com/user-attachments/assets/13bfb8b4-29da-4f8e-a283-c34a4f70709f" />
