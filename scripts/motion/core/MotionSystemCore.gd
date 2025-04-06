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

# List of subsystem paths to auto-register
var _subsystem_paths = [
	"res://scripts/motion/subsystems/BounceSystem.gd",
	"res://scripts/motion/subsystems/ObstacleSystem.gd",
	"res://scripts/motion/subsystems/EquipmentSystem.gd",
	"res://scripts/motion/subsystems/TraitSystem.gd",
	"res://scripts/motion/subsystems/EnvironmentalForceSystem.gd",
	"res://scripts/motion/subsystems/StatusEffectSystem.gd",
	"res://scripts/motion/subsystems/CollisionMaterialSystem.gd",
	"res://scripts/motion/subsystems/LaunchSystem.gd"
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
			push_warning("[MotionSystemCore] Failed to load physics config as PhysicsConfig resource")
	else:
		push_warning("[MotionSystemCore] Physics config not found at " + config_path)
	
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
		push_warning("[MotionSystemCore] Subsystem '%s' is already registered" % subsystem_name)
		return false
	
	# Set the motion_system reference in the subsystem IF it has the variable
	if "_motion_system" in subsystem: # Use 'in' to check for property existence
		subsystem._motion_system = self
	else:
		# Optional: Warn if a subsystem doesn't have the expected variable, 
		# if it's intended for all subsystems needing the reference.
		# push_warning("[MotionSystemCore] Subsystem '%s' does not have a '_motion_system' variable." % subsystem_name)
		pass 
	
	_subsystems[subsystem_name] = subsystem
	subsystem.on_register()
	
	# Subsystem registered
	subsystem_registered.emit(subsystem_name)
	return true

# Unregister a subsystem from the motion system
# subsystem_name: The name of the subsystem to unregister
# Returns: True if unregistration was successful, false otherwise
func unregister_subsystem(subsystem_name: String) -> bool:
	if not _subsystems.has(subsystem_name):
		push_warning("[MotionSystemCore] Subsystem '%s' is not registered" % subsystem_name)
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
	
	print("[MotionSystemCore] Auto-registering subsystems...")
	
	for path in _subsystem_paths:
		if ResourceLoader.exists(path):
			var subsystem_script = load(path)
			if subsystem_script:
				var subsystem = subsystem_script.new()
				if register_subsystem(subsystem):
					success_count += 1
					print("[MotionSystemCore] Successfully registered subsystem: ", subsystem.get_name())
				else:
					push_warning("[MotionSystemCore] Failed to register subsystem from path: " + path)
			else:
				push_warning("[MotionSystemCore] Failed to load subsystem script: " + path)
		else:
			push_warning("[MotionSystemCore] Subsystem script not found: " + path)
	
	print("[MotionSystemCore] Auto-registered %d/%d subsystems" % [success_count, _subsystem_paths.size()])
	
	# Connect LaunchSystem's signal to BounceSystem's recording method
	var launch_system = get_subsystem("LaunchSystem")
	var bounce_system = get_subsystem("BounceSystem")
	
	if launch_system and bounce_system and bounce_system.has_method("record_launch"):
		# Forward the signal from LaunchSystem through MotionSystemCore
		if not launch_system.is_connected("entity_launched", Callable(self, "_on_launch_system_entity_launched")):
			launch_system.connect("entity_launched", Callable(self, "_on_launch_system_entity_launched"))
		
		# Connect our forwarded signal to BounceSystem
		if not is_connected("entity_launched", Callable(bounce_system, "record_launch")):
			entity_launched.connect(bounce_system.record_launch)
			
		print("[MotionSystemCore] Connected entity_launched signal to BounceSystem.record_launch")
	else:
		push_warning("[MotionSystemCore] Failed to connect entity_launched signal to BounceSystem")
	
	return success_count

# Signal handler for LaunchSystem's entity_launched signal
# Forwards the signal to our own entity_launched signal
func _on_launch_system_entity_launched(entity_id: int, launch_vector: Vector2, position: Vector2) -> void:
	# Forward the signal
	entity_launched.emit(entity_id, launch_vector, position)
