class_name MotionSystemCore
extends Node

# No need to preload classes that are globally available via class_name in Godot 4.4

signal subsystem_registered(subsystem_name: String)
signal subsystem_unregistered(subsystem_name: String)
# This signal is emitted by the LaunchSystem subsystem, not directly by MotionSystem
# Now includes the position at which the launch occurred.
@warning_ignore("unused_signal")
signal entity_launched(entity_id: int, launch_vector: Vector2, position: Vector2)

# Physics configuration resource
var physics_config: PhysicsConfig

# Legacy parameters - will be used as fallbacks if no config is loaded
var default_gravity: float = 1200.0
var default_ground_friction: float = 0.2  # Friction coefficient - lower means longer slides
var default_stop_threshold: float = 0.5  # Speed below which we consider the entity stopped

# Dictionary of registered subsystems
var _subsystems: Dictionary = {}

# Dictionary of pending signal connections
# Structure: { "provider_name": [{ "dependent": subsystem, "signal_name": "signal_name", "method": "method_name" }] }
var _pending_connections: Dictionary = {}

# List of subsystem paths to auto-register
var _subsystem_paths = [
	# Register signal providers first
	"res://scripts/motion/subsystems/launch_system/LaunchSystem.gd",

	# Then register dependent subsystems
	"res://scripts/motion/subsystems/bounce_system/BounceSystem.gd",  # Path to the new BounceSystem script
	"res://scripts/motion/subsystems/boost_system/BoostSystem.gd",    # Path to the new BoostSystem script
	"res://scripts/motion/subsystems/ObstacleSystem.gd", # ObstacleSystem now active
	# "res://scripts/motion/subsystems/EquipmentSystem.gd", # Removed placeholder
	# "res://scripts/motion/subsystems/TraitSystem.gd", # Removed placeholder
	# "res://scripts/motion/subsystems/EnvironmentalForceSystem.gd", # Removed placeholder
	# "res://scripts/motion/subsystems/player_status_modifier_system/PlayerStatusModifierSystem.gd", # Removed - see README.md for future expansion
	"res://scripts/motion/subsystems/collision_material_system/CollisionMaterialSystem.gd" # Updated path
]

# Debug flag to enable/disable debug prints
var debug_enabled: bool = false

# References to other components
var physics_calculator = null
var state_manager = null
var continuous_resolver = null
var collision_resolver = null
var debugger = null
var _motion_profile_resolver: MotionProfileResolver = null # Added resolver reference

func _init() -> void:
	# Load physics configuration
	var config_path = "res://resources/physics/default_physics.tres"
	if ResourceLoader.exists(config_path):
		physics_config = load(config_path) as PhysicsConfig
		if physics_config:
			# Update legacy parameters from config
			default_gravity = physics_config.gravity
			default_ground_friction = physics_config.default_ground_friction
			default_stop_threshold = physics_config.default_stop_threshold
			
			if debug_enabled or OS.is_debug_build():
				print("MotionSystemCore: Loaded PhysicsConfig from ", config_path)
		else:
			push_warning("MotionSystemCore: Failed to load PhysicsConfig as resource. Using defaults.")
	else:
		push_warning("MotionSystemCore: PhysicsConfig file not found at ", config_path, ". Using defaults.")

	physics_calculator = load("res://scripts/motion/core/PhysicsCalculator.gd").new(self)
	state_manager = load("res://scripts/motion/core/MotionStateManager.gd").new(self)
	continuous_resolver = load("res://scripts/motion/core/ContinuousMotionResolver.gd").new(self)
	collision_resolver = load("res://scripts/motion/core/CollisionMotionResolver.gd").new(self)
	debugger = load("res://scripts/motion/core/MotionDebugger.gd").new(self)

# Returns the loaded physics configuration resource
func get_physics_config() -> PhysicsConfig:
	return physics_config

func _ready() -> void:
	set_debug_enabled(false) # Debug mode disabled by default

	# Note: Subsystems are registered when initialize_subsystems() is called
	# This allows for more dynamic control over when subsystems are loaded

# Enable or disable debug prints for the motion system and resolver
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	if debugger:
		debugger.set_debug_enabled(enabled)

# Register a subsystem with the motion system
# subsystem: An object implementing the IMotionSubsystem interface
# Returns: True if registration was successful, false otherwise
func register_subsystem(subsystem) -> bool:
	var subsystem_name = subsystem.get_name()

	if _subsystems.has(subsystem_name):
		return false

	# Set the motion_system reference in the subsystem IF it has the variable
	if "_motion_system" in subsystem: # Use 'in' to check for property existence
		subsystem._motion_system = self
	else:
		pass # Subsystem doesn't have _motion_system variable

	_subsystems[subsystem_name] = subsystem
	
	# Pass PhysicsConfig if the subsystem needs it
	if physics_config and subsystem.has_method("set_physics_config"):
		subsystem.set_physics_config(physics_config)
		if debug_enabled:
			print("MotionSystemCore: Passed PhysicsConfig to %s" % subsystem_name)
			
	# Call the subsystem's registration hook
	subsystem.on_register()

	# Connect signals based on dependencies
	_connect_subsystem_signals(subsystem)

	# Process any pending connections for this subsystem
	_process_pending_connections(subsystem_name)

	subsystem_registered.emit(subsystem_name)
	return true

# Process any pending signal connections for a newly registered subsystem
# subsystem_name: The name of the subsystem that was just registered
func _process_pending_connections(subsystem_name: String) -> void:
	if not _pending_connections.has(subsystem_name):
		return

	var provider = _subsystems[subsystem_name]
	var pending = _pending_connections[subsystem_name]

	for connection in pending:
		var dependent = connection.get("dependent")
		var signal_name = connection.get("signal_name")
		var method_name = connection.get("method")

		if not provider.has_signal(signal_name):
			continue

		if not dependent.has_method(method_name):
			continue

		if not provider.is_connected(signal_name, Callable(dependent, method_name)):
			provider.connect(signal_name, Callable(dependent, method_name))

	_pending_connections.erase(subsystem_name)

# Connect signals between subsystems based on dependencies
# subsystem: The subsystem to connect signals for
func _connect_subsystem_signals(subsystem) -> void:
	if not subsystem.has_method("get_signal_dependencies"):
		return

	var dependencies = subsystem.get_signal_dependencies()
	if dependencies.is_empty():
		return

	# Connect each dependency
	for dependency in dependencies:
		var provider_name = dependency.get("provider", "")
		var signal_name = dependency.get("signal_name", "")
		var method_name = dependency.get("method", "")

		if provider_name.is_empty() or signal_name.is_empty() or method_name.is_empty():
			continue

		if not _subsystems.has(provider_name):
			if not _pending_connections.has(provider_name):
				_pending_connections[provider_name] = []

			_pending_connections[provider_name].append({
				"dependent": subsystem,
				"signal_name": signal_name,
				"method": method_name
			})
			continue

		var provider = _subsystems[provider_name]

		if not provider.has_signal(signal_name):
			continue

		if not subsystem.has_method(method_name):
			continue

		if not provider.is_connected(signal_name, Callable(subsystem, method_name)):
			provider.connect(signal_name, Callable(subsystem, method_name))

# Unregister a subsystem from the motion system
# subsystem_name: The name of the subsystem to unregister
# Returns: True if unregistration was successful, false otherwise
func unregister_subsystem(subsystem_name: String) -> bool:
	if not _subsystems.has(subsystem_name):
		return false

	var subsystem = _subsystems[subsystem_name]
	subsystem.on_unregister()
	_subsystems.erase(subsystem_name)

	subsystem_unregistered.emit(subsystem_name)
	return true

# Get a registered subsystem by name
# subsystem_name: The name of the subsystem to get
# Returns: The subsystem, or null if not found
func get_subsystem(subsystem_name: String):
	return _subsystems.get(subsystem_name)

# Get all registered subsystems
# Returns: Dictionary of subsystems (name -> subsystem)
func get_all_subsystems() -> Dictionary:
	return _subsystems.duplicate()

# Resolve continuous motion (called every physics frame)
# delta: Time since last frame
# player_node: The player node for context (needed by profile resolver)
# delta: Time since last frame
# is_sliding: Whether the entity is currently sliding
# Returns: The final motion vector
func resolve_continuous_motion(player_node: Node, delta: float, is_sliding: bool = false) -> Vector2:
	# Resolve motion profile first
	var motion_profile = {}
	if _motion_profile_resolver:
		# Ensure player_node is valid before passing
		if is_instance_valid(player_node):
			motion_profile = _motion_profile_resolver.resolve_motion_profile(player_node)
		else:
			push_error("MotionSystemCore: Invalid player_node in resolve_continuous_motion.")
			motion_profile = MotionProfileResolver.DEFAULTS.duplicate() # Use defaults if player invalid
	else:
		# Fallback if resolver is not set (should not happen in normal operation)
		motion_profile = MotionProfileResolver.DEFAULTS.duplicate()
		push_warning("MotionSystemCore: MotionProfileResolver not available in resolve_continuous_motion.")

	# Pass relevant profile parameters to the continuous resolver
	# The continuous_resolver needs to be updated to accept these.
	# For now, we pass the profile in the context dictionary.
	var context = {
		"profile": motion_profile,
		"is_sliding": is_sliding
		# Add other relevant context if needed by continuous_resolver
	}
	# Assuming continuous_resolver.resolve signature is updated to accept context dictionary
	return continuous_resolver.resolve(delta, context, _subsystems)


# Resolve frame motion (called every physics frame)
# context: Dictionary containing motion context (position, velocity, delta, etc.)
# Returns: Dictionary containing motion result (velocity, has_launched, is_sliding, etc.)
func resolve_frame_motion(context: Dictionary) -> Dictionary:
	return state_manager.resolve_frame_motion(context)

# Resolve collision (called when a collision occurs)
# collision_info: Information about the collision
# Returns: Dictionary containing collision result (velocity, has_launched, is_sliding, etc.)
func resolve_collision(collision_info: Dictionary) -> Dictionary:
	return collision_resolver.resolve_collision(collision_info, _subsystems)

# Resolve a scalar value (like friction) with modifiers from all subsystems
# type: The type of scalar to resolve (e.g., "friction", "bounce")
# base_value: The base value to modify
# Returns: The final scalar value
func resolve_scalar(type: String, base_value: float) -> float:
	return continuous_resolver.resolve_scalar(type, base_value, _subsystems)

# Register all subsystems from the predefined list
# Returns: Number of successfully registered subsystems
func register_all_subsystems() -> int:
	var success_count = 0

	for path in _subsystem_paths:
		if ResourceLoader.exists(path):
			var subsystem_script = load(path)
			if subsystem_script:
				# Instantiate subsystem using its script's new() method
				# Removed special case for old ModularBounceSystem
				var subsystem = subsystem_script.new()

				if register_subsystem(subsystem):
					success_count += 1
				else:
					pass # Subsystem registration failed
			else:
				pass # Subsystem script load failed
		else:
			pass # Subsystem path doesn't exist

	return success_count


# --- Resolver Integration ---

## Called by Game.gd (or similar) to provide the resolver instance.
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
	_motion_profile_resolver = resolver
	if debug_enabled:
		print("MotionSystemCore: MotionProfileResolver initialized.")
