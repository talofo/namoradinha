class_name MotionSystemCore
extends Node

# Reference to physics config class
# Using LoadedPhysicsConfig to avoid shadowing the global class name
const LoadedPhysicsConfig = preload("res://resources/physics/PhysicsConfig.gd")

signal subsystem_registered(subsystem_name: String)
signal subsystem_unregistered(subsystem_name: String)
# This signal is emitted by the LaunchSystem subsystem, not directly by MotionSystem
# Now includes the position at which the launch occurred.
@warning_ignore("unused_signal")
signal entity_launched(entity_id: int, launch_vector: Vector2, position: Vector2)

# Physics configuration resource
var physics_config: LoadedPhysicsConfig

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
	"res://scripts/motion/subsystems/bounce_system/BounceSystem.gd",  # Uses ModularBounceSystem class
	"res://scripts/motion/subsystems/boost_system/BoostSystem.gd",
	"res://scripts/motion/subsystems/ObstacleSystem.gd",
	"res://scripts/motion/subsystems/EquipmentSystem.gd",
	"res://scripts/motion/subsystems/TraitSystem.gd",
	"res://scripts/motion/subsystems/EnvironmentalForceSystem.gd",
	"res://scripts/motion/subsystems/StatusEffectSystem.gd",
	"res://scripts/motion/subsystems/CollisionMaterialSystem.gd"
]

# Debug flag to enable/disable debug prints
var debug_enabled: bool = false

# References to other components
var physics_calculator = null
var state_manager = null
var continuous_resolver = null
var collision_resolver = null
var debugger = null

func _init() -> void:
	# Load physics configuration
	var config_path = "res://resources/physics/default_physics.tres"
	if ResourceLoader.exists(config_path):
		physics_config = load(config_path) as LoadedPhysicsConfig
		if physics_config:
			# Update legacy parameters from config
			default_gravity = physics_config.gravity
			default_ground_friction = physics_config.default_ground_friction
			default_stop_threshold = physics_config.default_stop_threshold
		else:
			pass # Logging removed
	else:
		pass # Logging removed

	# Initialize components
	physics_calculator = load("res://scripts/motion/core/PhysicsCalculator.gd").new(self)
	state_manager = load("res://scripts/motion/core/MotionStateManager.gd").new(self)
	continuous_resolver = load("res://scripts/motion/core/ContinuousMotionResolver.gd").new(self)
	collision_resolver = load("res://scripts/motion/core/CollisionMotionResolver.gd").new(self)
	debugger = load("res://scripts/motion/core/MotionDebugger.gd").new(self)

# Returns the loaded physics configuration resource
func get_physics_config() -> LoadedPhysicsConfig:
	return physics_config

func _ready() -> void:
	# Initialize with debug mode off by default
	set_debug_enabled(false)

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
		# Logging removed
		return false

	# Set the motion_system reference in the subsystem IF it has the variable
	if "_motion_system" in subsystem: # Use 'in' to check for property existence
		subsystem._motion_system = self
	else:
		# Optional: Warn if a subsystem doesn't have the expected variable, 
		# if it's intended for all subsystems needing the reference.
		# # Logging removed
		pass

	_subsystems[subsystem_name] = subsystem
	subsystem.on_register()

	# Connect signals based on dependencies
	_connect_subsystem_signals(subsystem)

	# Process any pending connections for this subsystem
	_process_pending_connections(subsystem_name)

	# Subsystem registered
	subsystem_registered.emit(subsystem_name)
	return true

# Process any pending signal connections for a newly registered subsystem
# subsystem_name: The name of the subsystem that was just registered
func _process_pending_connections(subsystem_name: String) -> void:
	# Skip if there are no pending connections for this subsystem
	if not _pending_connections.has(subsystem_name):
		return

	var provider = _subsystems[subsystem_name]
	var pending = _pending_connections[subsystem_name]

	# Logging removed, subsystem_name])

	# Process each pending connection
	for connection in pending:
		var dependent = connection.get("dependent")
		var signal_name = connection.get("signal_name")
		var method_name = connection.get("method")

		# Skip if provider doesn't have the signal
		if not provider.has_signal(signal_name):
			# Logging removed
			continue

		# Skip if dependent doesn't have the method
		if not dependent.has_method(method_name):
			# Logging removed])
			continue

		# Connect the signal
		if not provider.is_connected(signal_name, Callable(dependent, method_name)):
			provider.connect(signal_name, Callable(dependent, method_name))
			# Connected pending signal

	# Clear the pending connections for this subsystem
	_pending_connections.erase(subsystem_name)

# Connect signals between subsystems based on dependencies
# subsystem: The subsystem to connect signals for
func _connect_subsystem_signals(subsystem) -> void:
	# Skip if subsystem doesn't implement the signal dependency methods
	if not subsystem.has_method("get_signal_dependencies"):
		return

	# Get signal dependencies
	var dependencies = subsystem.get_signal_dependencies()
	if dependencies.is_empty():
		return

	# Connect each dependency
	for dependency in dependencies:
		var provider_name = dependency.get("provider", "")
		var signal_name = dependency.get("signal_name", "")
		var method_name = dependency.get("method", "")

		# Skip if any required field is missing
		if provider_name.is_empty() or signal_name.is_empty() or method_name.is_empty():
			# Logging removed)
			continue

		# If provider doesn't exist yet, store the connection request for later
		if not _subsystems.has(provider_name):
			# Logging removed])

			# Initialize the pending connections array for this provider if it doesn't exist
			if not _pending_connections.has(provider_name):
				_pending_connections[provider_name] = []

			# Store the connection request
			_pending_connections[provider_name].append({
				"dependent": subsystem,
				"signal_name": signal_name,
				"method": method_name
			})
			continue

		var provider = _subsystems[provider_name]

		# Skip if provider doesn't have the signal
		if not provider.has_signal(signal_name):
			# Logging removed
			continue

		# Skip if subsystem doesn't have the method
		if not subsystem.has_method(method_name):
			# Logging removed])
			continue

		# Connect the signal
		if not provider.is_connected(signal_name, Callable(subsystem, method_name)):
			provider.connect(signal_name, Callable(subsystem, method_name))
			# Connected signal

# Unregister a subsystem from the motion system
# subsystem_name: The name of the subsystem to unregister
# Returns: True if unregistration was successful, false otherwise
func unregister_subsystem(subsystem_name: String) -> bool:
	if not _subsystems.has(subsystem_name):
		# Logging removed
		return false

	var subsystem = _subsystems[subsystem_name]
	subsystem.on_unregister()
	_subsystems.erase(subsystem_name)

	# Subsystem unregistered
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
# is_sliding: Whether the entity is currently sliding
# Returns: The final motion vector
func resolve_continuous_motion(delta: float, is_sliding: bool = false) -> Vector2:
	return continuous_resolver.resolve(delta, is_sliding, _subsystems)

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

	# Logging removed

	for path in _subsystem_paths:
		if ResourceLoader.exists(path):
			var subsystem_script = load(path)
			if subsystem_script:
				var subsystem
				
				# Special case for BounceSystem - use ModularBounceSystem class
				if path == "res://scripts/motion/subsystems/bounce_system/BounceSystem.gd":
					subsystem = ModularBounceSystem.new()
					# Logging removed
				else:
					subsystem = subsystem_script.new()
				
				if register_subsystem(subsystem):
					success_count += 1
					# Logging removed)
				else:
					pass # Logging removed
			else:
				pass # Logging removed
		else:
			pass # Logging removed

	# Logging removed])

	return success_count
