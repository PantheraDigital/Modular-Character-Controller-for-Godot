# Modular-Character-Controller-for-Godot
**Contact:** pantheradigitalonline@gmail.com

[Demo Video](https://youtu.be/ABDJnFag9q8) \
[Play the Demo Level](https://pantheraonline.itch.io/godot-modular-character-controller)

## About

This pack provides scripts that make it faster to develop well organize and reusable code for controllable characters. This is done by separating the code of a character out into actions that get attached to the character using Nodes, thus separating the logic into smaller more modular components that can be moved around and edited more easily.

_The term "character" is used loosely here but is used to follow Godot's naming, specifically due to Godot's naming of Character Body 3D which is a "physics body specialized for characters moved by script". In the context of this pack a "character" is anything that may be controlled by a player or game AI. A character may be a person, car, bird, or magical floating sword._

_Also, the term "AI" is used in the way it is game development, that being a script on an NPC that might just be a bunch of 'if' statements._

## Features
- Action Nodes - separates out logic for characters into organized nodes
- Action Container - manages Action Nodes allowing them to be used dynamically as well as safely called by Controllers
- Action Container Configurations - defined sets of actions that can be quickly swapped between at runtime on a character
- Controller - the bridge between user and character separating input from character logic
- Movement States - nodes responsible for processing the characters physics during different forms of movement (EX: grounded, flying, swimming)
- Movement State Manager - a node for changing the active Movement State of a character

## Includes
- 2 example characters
- 1 player controller
- 1 npc controller
- 2 movement state examples
- some example actions for characters

## Example Level

In the level there are two characters. One is the Simple Character and the other the Example Character that are both included in the pack. The Simple (green) uses a first person camera and is the equivalent of using Godot's CharacterBody3D's Basic Movement template script. The Example Character (orange) uses a third person camera and starts off with a simple AI Controller script making it walk in circles. It uses a more complex movement script allowing it to step up and down ledges such as stairs, and it can switch between movement states to fly or walk.

In the level is also a purple cube that will add a "Dash" action to any character that walks into it.

### Controls
- WASD - move
- space - jump
- alt - dash (if obtained)
- tab - swap characters
- double tap space when controlling the third person character - toggle between flying and walking


## Getting Started
### Download
As a project:
- download the zip folder from github
- unzip the folder where you want the Godot project to be
- add the project to the Godot Project Manager using the Scan tool where you unzipped the project

As an addon for an existing Godot project
- download the character_controller folder (or the entire project and extract the folder)
- place the character_controller folder in a folder named "addons" in the existing project (make sure the character_controller folder is unzipped)

You should now be able to use the code to make your characters.

### Making a Character
Two example characters are provided, one is a simple character meant to reflect the Godot CharacterBody3D template script, and the other is a more complex example to further demonstrate how characters work with these scripts.

To create your own character

- Create a scene for the character using the CharacterBody3D node
- Add a collision shape and mesh so the character can exist in the world
- Add a Node3D with the included "first_person_cam.gd" as the script and "CamPivot" as the name
- Add a Camera3D as a child to CamPivot then position the Node3D at head height
- Now add two Nodes to the character, one called "ActionContainer" and one called "GroundedMovement"
- Add "action_container.gd" to ActionContainer and add "movement_grounded_simple.gd" to GroundedMovement
- Make sure the "Enabled" variable is set to On in the inspector for the GroundedMovement node
- Add two more Nodes, but as children to ActionContainer and name them "Move" and "Jump"
- Add the script "action_move_simple.gd" to Move and "action_jump_simple.gd" to Jump

<img width="299" height="427" alt="Screenshot from 2025-09-01 00-40-30" src="https://github.com/user-attachments/assets/16f02f8e-0ac7-45d5-9211-12bcfc961fc4" />

You will now have a character ready to be controlled that is capable of moving and jumping and has a first person camera. 

- Now create a new scene that will be the level
- Add at least a floor with either a Mesh Instance 3D with a Static Body 3D node child and CollisionShape node, or use a CSGBox that has the "Use Collision" variable set to true
- Drag in your created character to the scene
- Add a new Node to the level scene and call it PlayerController, then attach the "controller_player.gd" script
- In the inspector for PlayerController, set the "Controlled Obj" variable to the character you created and added to the level

<img width="298" height="467" alt="Screenshot from 2025-09-01 00-47-46" src="https://github.com/user-attachments/assets/bff30d1a-905e-445d-a408-4b20d664272d" />

Finally the controls need to be set up in the Godot project.

- Go to Project -> Project Setting -> Input Map
- Add actions "move_left", "move_right", "move_forwards", "move_backwards", "jump", and "dash"
- Bind the actions to any inputs you like

<img width="1194" height="733" alt="Screenshot from 2025-09-01 00-49-33" src="https://github.com/user-attachments/assets/5d13765a-f582-492b-950e-8c05065642d8" />

You should now have a level with a character that can be controlled by the player.

## How To Use
_Note: Examples for Action Nodes, Controller, Movement State, and Action Containerare designed to emulate the Godot CharacterBody3D template script and result in a very basic controllable character._
<img width="1101" height="801" alt="GodotCharacterTemplate" src="https://github.com/user-attachments/assets/4574f2e7-d961-45a7-8f39-95ce8046d8ff" />


### Action Nodes
Action Nodes are the implementation of actions that a character can perform. These actions are like a public interface to the character that other objects use to tell the character what to do in order to control, or instruct, the character. When controlling a character, other nodes/scripts on the character should be thought of as private, internal systems, from the perspective of the other object. This is to say that only Action Nodes should be used when trying to make the character actually do something. 

Consider "what should be an action and what should be an internal system in the character" when creating Action Nodes, remembering that Action Nodes act as a public API to the character. 

**IDs**
Action Nodes identify the action they will have the character perform by using an ID. This ID is what should be used when finding which Action Node to call. IDs may also be shared between multiple Action Nodes. When using IDs in this way only one Action Node of that ID should be active while the others are ignored. This allows for swapping out Action Nodes while keeping an action still usable.

**Layered Actions**
Action Nodes also come in two forms, Layered and Not Layered. A non-layered action simply means that if it is playing no other actions will play, while actions labeled as layered can all play together. This is useful in the case of moving and running. The moving action has the logic for adding velocity but the running action changes the variable used by the moving action so the velocity is increased. Running would be impossible if only one of these actions could take place at a time. This also helps reduce repeating code since both run and move could hold the same logic but with the difference of the velocity added, but this would bloat the project and lead to future problems if changes are made to how the character should move. Layered actions also get interrupted by non-layered actions, so that in cases like "move" the "jump" action will take priority, do its thing, then allow "move" to continue afterword. 

**Interrupt Whitelist**
An Interrupt Whitelist is also defined in Action Nodes that is used to define other Action Nodes that may interrupt the current action. This is used by non-layered actions since layered actions naturally play over each other. The Interrupt Whitelist can be set when the Action Node init() function is called, or at run time to change which actions can interrupt as the action is playing. The Interrupt Whitelist allows not only other layered actions to interrupt the current action, cutting it short, but also allows non-layered actions to "interrupt", which allows them to play along with the current non-layered action. Consider a character who attacks by swinging a sword, but you don't want to lock them in place and rather they move freely. In this case the Attack Action Node would define "move" in its Interrupt Whitelist.

_Example Move and Jump Action Node Scripts_ \
<img width="1101" height="801" alt="ActionMove" src="https://github.com/user-attachments/assets/424c4b66-ab9c-4dc7-8fb3-7da5dade09de" />
<img width="1101" height="801" alt="ActionJump" src="https://github.com/user-attachments/assets/02c387d1-6d37-4f39-ba17-d8ce1e4d29af" />

### Controller
The character is designed to have actions it can perform, but it cannot act on its own. This is what the Controller is for. It acts as the brain while the character is just the body, or another perspective is the character is a puppet and the Controller is the master. The Controller is an external object with the purpose of manipulating a character through the use of the character's actions. This is made easier using the Action Container. 

While it acts as a brain in the case of AI controlled characters, it also serves the purpose of bridging player input to actions. This does mean different controllers may be needed to control characters that have significantly different actions, or even characters who's actions may change drastically during gameplay.

This can be mitigated through the use of generic action IDs, allowing the Controller to tell a character to "move" and have that action work regardless of if the character is a human or vehicle. The use of action IDs can be used similarly to polymorphism, where one ID may be used on multiple actions but by swapping the active action the same ID can be called but with a different result.

_Example Controller Script_ \
<img width="1101" height="801" alt="Controller" src="https://github.com/user-attachments/assets/353101a8-5d32-4b5c-a45d-5edcc9eff773" />

### Movement State
Movement States are the implementation of a characters movement logic. Gravity, velocity, and floor snap for example. 

Since characters cover many forms it is very likely they will behave and move differently. For this reason the Movement State script provides a common interface for moving a character. This also means polymorphism can be used on the Movement State of characters. 

Movement States allow actions to easily move a character without concern over how the character should move or the implementation. This not only makes Action Nodes more reusable across different characters but also allows characters to easily change Movement States at runtime without breaking references. 

_Example Movement State Script_ \
<img width="1101" height="801" alt="MovementState" src="https://github.com/user-attachments/assets/72989895-6f63-48b2-bf2c-372a50a18f9f" />

### Action Container 
A character will have many actions, and may have actions that should be available during some states but not others. Making a Controller search a character for a specific Action Node every time it wants to trigger an action would be very slow. 

The Action Container makes Action Node management easier. It tracks which Action Nodes it is the parent of and which are active. It allows for safe calling of Action Nodes, easy removal and addition of Action Nodes, and configuration of which Action Nodes should be active, or usable, in a given state.

Any character with Action Nodes should use the Action Container as a parent to their Action Nodes and as a sign the character is controllable by external objects.

_Example of Action Container in character node tree_ \
<img width="262" height="590" alt="CharacterNodes" src="https://github.com/user-attachments/assets/517df8c3-90b4-4037-a194-6ee2d5a9d2a6" />

#### Action Container Config
Complex and dynamic characters will have actions that are only usable in specific states. To make managing Action Nodes in an Action Container the Action Container Config is a resource used by Action Container which allows "profiles" to be defined. A profile is a list of actions that are usable when that profile is active. Using the Action Container to set an active profile will make it so only the listed actions are usable.

_Example of Config set in the inspector on a more complex character_ \
<img width="262" height="590" alt="ComplexCharacterNodes" src="https://github.com/user-attachments/assets/745c4bca-0fc8-4a19-a6a5-4637f45ab210" />
<img width="483" height="766" alt="ComplexCharacterActionConfig" src="https://github.com/user-attachments/assets/75919637-aaab-4bd8-9321-115609bb0631" />

### Movement State Manager
The movement State Manager is a simple container for managing multiple Movement States on a single character by setting one as active and ignoring the rest. This container can then be called to get the active Movement State.

_Example of Movement State Manager being used to change Movement State through the use of an Action Node_ \
<img width="262" height="590" alt="ComplexCharacterNodes2" src="https://github.com/user-attachments/assets/868a878f-e7a8-4cfe-a6e0-1c3aad11ccb8" />
<img width="1124" height="801" alt="ComplexCharacterMoveStateChangeNode" src="https://github.com/user-attachments/assets/ba208263-2159-45da-9bc0-d1b1cc4eb269" />

## Resulting Character
Here is the result from the examples above, excluding Action Container Config and Movement State Manager. This character is expected to work the same as a character with the Godot CharacterBody3D template script. To see the more complex character used in the Action Container Config example and the Movement State Manager example see the [Example Character](controller_examples/scenes/ExampleCharacter.tscn) found in the controller_examples folder, or [play the demo level](https://pantheraonline.itch.io/godot-modular-character-controller).

_Character Nodes_ \
<img width="262" height="590" alt="CharacterNodes" src="https://github.com/user-attachments/assets/82456fbd-5f9d-40bd-a8cf-6cc7ff615ce2" /> \
_Level Nodes_ \
<img width="262" height="590" alt="LevelNodes" src="https://github.com/user-attachments/assets/566a1e38-dd63-4b3a-8785-3af1877c78f8" /> \
_Gameplay_ \
<video src="https://github.com/user-attachments/assets/a95a3766-e900-4915-b08f-874b2043ea1f" width="320" height="240" controls></video>



