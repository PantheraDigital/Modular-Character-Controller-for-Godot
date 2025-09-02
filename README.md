# Modular-Character-Controller-for-Godot

[Demo Video](https://youtu.be/ABDJnFag9q8)
[Support](https://pantheraonline.itch.io/godot-modular-character-controller)

## Example Level

This demo level is to show what can be done at a base level with this pack and to demonstrate the flexibility of decoupling input handling, action logic, and movement logic into their own nodes.

### Controls

- WASD - move
- space - jump
- alt - dash (if obtained)
- tab - swap characters
- double tap space when controlling the third person character - toggle between flying and walking

In the level there are two characters. One is the Simple Character and the other the Example Character that are both included in the pack. The Simple (green) uses a first person camera and is the equivalent of using Godot's CharacterBody3D's Basic Movement template script. The Example Character (orange) uses a third person camera and starts off with a simple AI Controller script making it walk in circles. It uses a more complex movement script allowing it to step up and down ledges such as stairs, and it can switch between movement states to fly or walk.

In the level is also a purple cube that will add a "Dash" action to any character that walks into it.

## About

This pack provides scripts that make it faster to develop well organize and reusable code for controllable characters. This is done by separating the code of a character out into actions that get attached to the character using Nodes, thus separating the logic into smaller more modular components that can be moved around and edited more easily.

_The term "character" is used loosely here but is used to follow Godot's naming, specifically due to Godot's naming of Character Body 3D which is a "physics body specialized for characters moved by script". In the context of this pack a "character" is anything that may be controlled by a player or game AI. A character may be a person, car, bird, or magical floating sword.

Also, the term "AI" is used in the way it is game development, that being a script on an NPC that might just be a bunch of 'if' statements._

## Features
- Action Nodes - separates out logic for characters into organized nodes
- Action Container - manages Action Nodes allowing them to be used dynamically as well as safely called by Controllers
- Action Container Configurations - defined sets of actions that can be quickly swapped between at runtime on a character
- Controller - the bridge between user and character separating input from character logic
- Movement States - nodes responsible for processing the characters physics during different forms of movement (EX: grounded, flying, swimming)
- Movement State Manager - a node for changing the active Movement State of a character  

## Getting Started

Two example characters are provided, one is a simple character with a minimal set up while the other is more complex. 

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

## The Components

There are three main components that are the keys to how this pack works.

First are **_Action Nodes_** \
These are nodes that are attached to other nodes so that the base node may perform an action. Actions such as moving, running, attacking, climbing, or even interacting with an item. The Action Nodes are the implementation of these actions, so that when attached to another node, that node can perform the action. The naming is also related to Godot's Input Event Actions as they work closely together.

Second is the **_Action Container_** \
This is a node that Action Nodes can be attached to to make managing them during game play easier. It will store the child Action Nodes to making calling them faster as well as adding and removing them. Think of this as the API for telling a character what to do, while the Action Nodes are the concrete implementation of how the action should be done.

Lastly is the **_Controller_** \
This node acts as the bridge between, well the controller of a character (person or AI) and the character they currently control. As an example the Controller script for a player character would be where input is gathered, then used to determine what action should be done. The Action Container is then called and told what action to trigger, then it triggers the correct Action Node.

These components are used to separate out logic to prevent a monolithic character controller class but also to keep the character very flexible. With these scripts actions and even controllers can be swapped out at run time while also making it clear what a character can do during development. This decoupling of input handling and action logic make it very easy to add and edit what characters can do. 

This pack also comes with a Movement State script and Movement State Manager script which handle the actual movement logic of a character. This is where one would implement how a car would drive and how a person would walk and add it to the characters. The manager script also makes it so that different Movement States can be swapped between during game play, such as walking to flying or walking to grapple hook swinging. 
