class_name MotionSystem
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

# === PHYSICS CONFIGURATION ===
# Physics configuration resource
var physics_config: LoadedPhysicsConfig

# Legacy parameters - will be used as fallbacks if no config is loaded
var default_gravity: float = 1200.0 
var default_ground_friction: float = 0.2  # Friction coefficient - lower means longer slides
var default_stop_threshold: float = 0.5  # Speed below which we consider the entity stopped

# The resolver used to calculate final motion values
var resolver = null # Will be MotionResolver

# Dictionary of registered subsystems
var _subsystems: Dictionary = {}

# Debug flag to enable/disable debug prints
var debug_enabled: bool = false

func _init() -> void:
	resolver = load("res://scripts/motion/MotionResolver.gd").new()
	
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
			push_warning("[MotionSystem] Failed to load physics config as PhysicsConfig resource")
	else:
		push_warning("[MotionSystem] Physics config not found at " + config_path)

# Returns the loaded physics configuration resource
func get_physics_config() -> LoadedPhysicsConfig:
	return physics_config

func _ready() -> void:
	# Initialize with debug mode off by default
	set_debug_enabled(false)

# Enable or disable debug prints for the motion system and resolver
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled
	resolver.debug_enabled = enabled

# Register a subsystem with the motion system
# subsystem: An object implementing the IMotionSubsystem interface
# Returns: True if registration was successful, false otherwise
func register_subsystem(subsystem) -> bool:
	var subsystem_name = subsystem.get_name()
	
	if _subsystems.has(subsystem_name):
		push_warning("[MotionSystem] Subsystem '%s' is already registered" % subsystem_name)
		return false
	
	# Set the motion_system reference in the subsystem IF it has the variable
	if "_motion_system" in subsystem: # Use 'in' to check for property existence
		subsystem._motion_system = self
	else:
		# Optional: Warn if a subsystem doesn't have the expected variable, 
		# if it's intended for all subsystems needing the reference.
		# push_warning("[MotionSystem] Subsystem '%s' does not have a '_motion_system' variable." % subsystem_name)
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
		push_warning("[MotionSystem] Subsystem '%s' is not registered" % subsystem_name)
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
	# Resolve continuous motion
	
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in _subsystems:
		var subsystem = _subsystems[subsystem_name]
		if subsystem.has_method("get_continuous_modifiers"):
			var modifiers = subsystem.get_continuous_modifiers(delta)
			
			# Filter out acceleration and wind modifiers during sliding
			if is_sliding:
				var filtered_modifiers = []
				for mod in modifiers:
					if mod.type != "wind" and mod.type != "acceleration":
						filtered_modifiers.append(mod)
				modifiers = filtered_modifiers
			
			# Collected modifiers from subsystem
			all_modifiers.append_array(modifiers)
	
	# Resolve the final motion vector
	if resolver and resolver.has_method("resolve_modifiers"):
		return resolver.resolve_modifiers(all_modifiers)
	else:
		push_warning("[MotionSystem] Resolver not available or missing resolve_modifiers method")
		return Vector2.ZERO

# Resolve frame motion (called every physics frame)
# context: Dictionary containing motion context (position, velocity, delta, etc.)
# Returns: Dictionary containing motion result (velocity, has_launched, is_sliding, etc.)
func resolve_frame_motion(context: Dictionary) -> Dictionary:
	# Resolve frame motion
	
	var result = {}
	
	# Apply gravity if entity is launched
	if context.has("has_launched") and context.get("has_launched"):
		var velocity = context.get("velocity", Vector2.ZERO)
		var delta = context.get("delta", 0.01) # Fallback to 0.01 if no delta
		
		print("MotionSystem: BEFORE gravity - velocity=", velocity, " (magnitude=", velocity.length(), ")")
		
		# Get appropriate gravity based on entity type and mass
		var entity_type = context.get("entity_type", "default")
		var mass = context.get("mass", physics_config.default_mass if physics_config else 1.0)
		
		# Get gravity from config or fallback to context or default
		var gravity = 0.0
		if physics_config:
			gravity = physics_config.get_gravity_for_entity(entity_type, mass)
		else:
			gravity = context.get("gravity", default_gravity)
		
		print("MotionSystem: Using gravity: ", gravity)
		
		velocity.y += gravity * delta
		result["velocity"] = velocity
		
		print("MotionSystem: AFTER gravity - velocity=", velocity, " (magnitude=", velocity.length(), ")")
	
	# Get continuous motion modifiers
	var motion_delta = resolve_continuous_motion(context.get("delta", 0.0), context.get("is_sliding", false))
	
	# Apply continuous motion modifiers to velocity
	if result.has("velocity"):
		result["velocity"] += motion_delta
	else:
		result["velocity"] = context.get("velocity", Vector2.ZERO) + motion_delta
	
	# Round velocity values to reduce visual jittering from small incremental changes
	result["velocity"].x = round(result["velocity"].x * 10) / 10.0
	result["velocity"].y = round(result["velocity"].y * 10) / 10.0
	
	print("MotionSystem: FINAL frame motion velocity=", result["velocity"], " (magnitude=", result["velocity"].length(), ")")
	
	return result

# Resolve collision motion (called when a collision occurs)
# collision_info: Information about the collision
# Returns: The final motion vector
func resolve_collision_motion(collision_info: Dictionary) -> Vector2:
	# Resolve collision motion
	
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in _subsystems:
		var subsystem = _subsystems[subsystem_name]
		if subsystem.has_method("get_collision_modifiers"):
			var modifiers = subsystem.get_collision_modifiers(collision_info)
			
			# Collected modifiers from subsystem
			
			all_modifiers.append_array(modifiers)
	
	# Resolve the final motion vector
	if resolver and resolver.has_method("resolve_modifiers"):
		return resolver.resolve_modifiers(all_modifiers)
	else:
		push_warning("[MotionSystem] Resolver not available or missing resolve_modifiers method")
		return Vector2.ZERO

# Resolve collision (called when a collision occurs)
# collision_info: Information about the collision
# Returns: Dictionary containing collision result (velocity, has_launched, is_sliding, etc.)
func resolve_collision(collision_info: Dictionary) -> Dictionary:
	# Resolve collision
	
	var result = {}
	var material_type = collision_info.get("material", "default")
	var velocity = collision_info.get("velocity", Vector2.ZERO)
	var has_launched = collision_info.get("has_launched", false)
	var is_sliding = collision_info.get("is_sliding", false)
	
	# Get the bounce system
	var collision_material_system = get_subsystem("CollisionMaterialSystem")

	# Handle bounce or slide based on current state
	if has_launched and velocity.y >= 0:
		# We're moving downward and have been launched, resolve collision motion (bounce or stop)
		print("MotionSystem: Entity is launched and moving downward, resolving collision motion...")

		# Get collision motion from subsystems (primarily BounceSystem)
		var collision_motion = resolve_collision_motion(collision_info)
		result["velocity"] = collision_motion
		print("MotionSystem: Collision motion resolved to: ", collision_motion)

		# Determine state based on resolved motion
		if is_zero_approx(collision_motion.y):
			# Bounce stopped, transition to slide
			# Preserve x-velocity with a small reduction to make the transition smoother
			var preserved_x_velocity = collision_motion.x * 0.98  # No velocity clamping to allow for unlimited jump heights
			result["velocity"] = Vector2(preserved_x_velocity, 0.0)
			result["has_launched"] = false
			result["is_sliding"] = true
			print("MotionSystem: Bounce stopped (y-velocity near zero). Transitioning to slide with velocity_x=", preserved_x_velocity)
		else:
			# Still bouncing
			result["has_launched"] = true
			result["is_sliding"] = false
			# Update max_height_y only when bouncing continues upwards
			if collision_motion.y < 0:
				result["max_height_y"] = collision_info.get("position", Vector2.ZERO).y
			print("MotionSystem: Continuing bounce.")

	elif is_sliding:
		# --- REFACTORED SLIDING LOGIC ---
		print("MotionSystem: Entity is sliding with velocity=", velocity)

		# Get necessary context
		var delta = collision_info.get("delta", get_process_delta_time()) # Use delta from context or physics process
		var stop_threshold = physics_config.default_stop_threshold if physics_config else default_stop_threshold
		# var frame_rate_adj = physics_config.frame_rate_adjustment if physics_config else 60.0 # Removed - Unused after physics-based friction refactor

		# 1. Get base friction
		var base_friction = physics_config.default_ground_friction if physics_config else default_ground_friction
		# Use the existing collision_material_system variable declared earlier in the function
		if collision_material_system: 
			var material_properties = collision_material_system.get_material_properties(material_type)
			base_friction = material_properties.get("friction", base_friction) # Use material friction if available

		# 2. Collect friction modifiers (Placeholder for future extension)
		var friction_modifiers = []
		# Example: Iterate subsystems and call a hypothetical get_friction_modifiers method
		# for subsystem in _subsystems.values():
		#     if subsystem.has_method("get_friction_modifiers"):
		#         friction_modifiers.append_array(subsystem.get_friction_modifiers(collision_info))

		# 3. Resolve effective friction (Placeholder for future extension)
		var effective_friction = base_friction
		if resolver and resolver.has_method("resolve_scalar_modifiers") and not friction_modifiers.is_empty():
			# If resolver and modifiers exist, use them
			effective_friction = resolver.resolve_scalar_modifiers(friction_modifiers, base_friction)
		# else: # For now, effective_friction remains base_friction

		# 4. Calculate consistent deceleration
		var speed = abs(velocity.x)
		var direction = sign(velocity.x)
		
		# Get gravity from config or use default
		var gravity = physics_config.gravity if physics_config else default_gravity

		# Physics-based deceleration model: proportional to effective friction and gravity
		var deceleration = effective_friction * gravity * delta

		# Ensure deceleration doesn't reverse velocity direction in one frame
		deceleration = min(deceleration, speed) # Deceleration cannot be greater than current speed

		# Calculate new speed
		var new_speed = speed - deceleration

		# 5. Apply results and check stop condition
		if new_speed < stop_threshold:
			# Stop completely
			result["velocity"] = Vector2.ZERO
			result["is_sliding"] = false
			result["just_stopped_sliding"] = true # Flag that we just stopped
			print("MotionSystem: Sliding stopped (speed ", new_speed, " < threshold ", stop_threshold, ")")
		else:
			# Continue sliding
			result["velocity"] = Vector2(direction * new_speed, 0.0)
			result["is_sliding"] = true # Ensure state remains sliding
			print("MotionSystem: Sliding with speed=", new_speed, ", deceleration=", deceleration, ", effective_friction=", effective_friction)
		# --- END REFACTORED SLIDING LOGIC ---
	
	return result

# Resolve a scalar value (like friction) with modifiers from all subsystems
# type: The type of scalar to resolve (e.g., "friction", "bounce")
# base_value: The base value to modify
# Returns: The final scalar value
func resolve_scalar(type: String, base_value: float) -> float:
	# Resolve scalar value
	
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in _subsystems:
		var subsystem = _subsystems[subsystem_name]
		if subsystem.has_method("get_continuous_modifiers"):
			var continuous_modifiers = subsystem.get_continuous_modifiers(0.0)
			
			# Filter for modifiers of the specified type
			for mod in continuous_modifiers:
				if mod.has("type") and mod.type == type:
					all_modifiers.append(mod)
	
	# Resolve the final scalar value
	if resolver and resolver.has_method("resolve_scalar_modifiers"):
		return resolver.resolve_scalar_modifiers(all_modifiers, base_value)
	else:
		push_warning("[MotionSystem] Resolver not available or missing resolve_scalar_modifiers method")
		return base_value
