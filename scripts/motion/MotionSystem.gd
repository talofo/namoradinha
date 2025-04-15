class_name MotionSystem
extends Node

# Core system that handles all motion-related functionality
var _core = null

# Forward signals from core
signal subsystem_registered(subsystem_name: String)
signal subsystem_unregistered(subsystem_name: String)

func _init() -> void:
	_core = load("res://scripts/motion/core/MotionSystemCore.gd").new()

	_core.subsystem_registered.connect(func(subsystem_name): subsystem_registered.emit(subsystem_name))
	_core.subsystem_unregistered.connect(func(subsystem_name): subsystem_unregistered.emit(subsystem_name))

func _ready() -> void:
	# Initialize with debug mode off by default
	set_debug_enabled(false)

	# Note: Subsystems are registered when MotionSystemCore.register_all_subsystems() is called externally (e.g., by Game.gd)

# Returns the loaded physics configuration resource
func get_physics_config():
	return _core.get_physics_config()

# Enable or disable debug prints for the motion system
func set_debug_enabled(enabled: bool) -> void:
	_core.set_debug_enabled(enabled)

# Register a subsystem with the motion system
# subsystem: An object implementing the IMotionSubsystem interface
# Returns: True if registration was successful, false otherwise
func register_subsystem(subsystem) -> bool:
	return _core.register_subsystem(subsystem)

# Unregister a subsystem from the motion system
# subsystem_name: The name of the subsystem to unregister
# Returns: True if unregistration was successful, false otherwise
func unregister_subsystem(subsystem_name: String) -> bool:
	return _core.unregister_subsystem(subsystem_name)

# Get a registered subsystem by name
# subsystem_name: The name of the subsystem to get
# Returns: The subsystem, or null if not found
func get_subsystem(subsystem_name: String):
	return _core.get_subsystem(subsystem_name)

# Get all registered subsystems
# Returns: Dictionary of subsystems (name -> subsystem)
func get_all_subsystems() -> Dictionary:
	return _core.get_all_subsystems()

# Resolve continuous motion (called every physics frame)
# player_node: The player node for context
# delta: Time since last frame
# is_sliding: Whether the entity is currently sliding
# Returns: The final motion vector
func resolve_continuous_motion(player_node: Node, delta: float, is_sliding: bool = false) -> Vector2:
	# Forward the call with the added player_node argument
	return _core.resolve_continuous_motion(player_node, delta, is_sliding)

# Resolve frame motion (called every physics frame)
# context: Dictionary containing motion context (position, velocity, delta, etc.)
# Returns: Dictionary containing motion result (velocity, has_launched, is_sliding, etc.)
func resolve_frame_motion(context: Dictionary) -> Dictionary:
	return _core.resolve_frame_motion(context)

# Resolve collision (called when a collision occurs)
# collision_info: Information about the collision
# Returns: Dictionary containing collision result (velocity, has_launched, is_sliding, etc.)
func resolve_collision(collision_info: Dictionary) -> Dictionary:
	return _core.resolve_collision(collision_info)

# Resolve a scalar value (like friction) with modifiers from all subsystems
# type: The type of scalar to resolve (e.g., "friction", "bounce")
# base_value: The base value to modify
# Returns: The final scalar value
func resolve_scalar(type: String, base_value: float) -> float:
	return _core.resolve_scalar(type, base_value)

# --- Resolver Integration ---

## Called by Game.gd to provide the resolver instance.
## Forwards the resolver to the MotionSystemCore instance.
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
	if _core and _core.has_method("initialize_with_resolver"):
		_core.initialize_with_resolver(resolver)
	else:
		push_error("MotionSystem: _core (MotionSystemCore) is missing or lacks initialize_with_resolver method.")
