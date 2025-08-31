extends Resource
class_name ActionContainerConfig

## used by ActionContainer to configure actions that can be called
## holds a "profile" of ActionNodes that can be performed when the profile is active
##
## actions must be nodes that are on the character
## actions in a profile must use the node name (this is to allow ACTION_IDs being shared across different configurations)

# key: profile name (EX: "Grounded")
# data: names of action Nodes to enable (EX: ["jump", "move", "run"]) # use node name, not ACTION_ID
@export var config_dict: Dictionary[StringName, Array]
