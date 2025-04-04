class_name MotionSystem
extends Node

# Reference to physics config class
# Using LoadedPhysicsConfig to avoid shadowing the global class name
const LoadedPhysicsConfig = preload("res://resources/physics/PhysicsConfig.gd")

signal subsystem_registered(subsystem_name: String)
signal subsystem_unregistered(subsystem_name: String)

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
		
		# Get appropriate gravity based on entity type and mass
		var entity_type = context.get("entity_type", "default")
		var mass = context.get("mass", physics_config.default_mass if physics_config else 1.0)
		
		# Get gravity from config or fallback to context or default
		var gravity = 0.0
		if physics_config:
			gravity = physics_config.get_gravity_for_entity(entity_type, mass)
		else:
			gravity = context.get("gravity", default_gravity)
		
		velocity.y += gravity * delta
		result["velocity"] = velocity
	
	# Get continuous motion modifiers
	var motion_delta = resolve_continuous_motion(context.get("delta", 0.0), context.get("is_sliding", false))
	
	# Apply continuous motion modifiers to velocity
	if result.has("velocity"):
		result["velocity"] += motion_delta
	else:
		result["velocity"] = context.get("velocity", Vector2.ZERO) + motion_delta
	
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
		# We're sliding, apply material-specific friction
		print("MotionSystem: Entity is sliding with velocity=", velocity)
		
		# Get entity properties
		var _entity_type = collision_info.get("entity_type", "default") # Underscore prefix as it's not yet used
		var entity_mass = collision_info.get("mass", physics_config.default_mass if physics_config else 1.0)
		var entity_size = collision_info.get("size_factor", physics_config.default_size_factor if physics_config else 1.0)
		
		# Get threshold from config or fallback
		var stop_threshold = physics_config.default_stop_threshold if physics_config else default_stop_threshold
		
		if collision_material_system:
			# Get material properties
			var material_properties = collision_material_system.get_material_properties(material_type)
			var friction = material_properties.get("friction", default_ground_friction)
			
			# Calculate speed and direction
			var speed = abs(velocity.x)
			var direction = sign(velocity.x)
			
			# Handle very low speeds with a more gradual approach
			if speed < stop_threshold * 2.0: # Expanded threshold zone for gradual slowdown
				# Instead of abrupt stop, use exponential decay
				var decay_rate = 0.7 # Higher = more gradual (0.9 = very slow, 0.1 = very fast)
				
				# Calculate new speed with decay
				var decayed_speed = speed * decay_rate
				
				# Never stop completely - allow for continuous sliding with very low speeds
				# Initialize final_speed outside the conditional so it's available in all scopes
				var final_speed = decayed_speed
				
				if decayed_speed < 0.1:
					# Finally come to a complete stop
					result["velocity"] = Vector2.ZERO
					result["is_sliding"] = false
					print("MotionSystem: Sliding stopped naturally")
				else:
					# Continue with gradual decay
					result["velocity"] = Vector2(direction * final_speed, 0.0)
					print("MotionSystem: Sliding with decayed speed=", final_speed)
			else:
				# Get physics parameters from config or use defaults
				var frame_rate_adj = physics_config.frame_rate_adjustment if physics_config else 60.0
				var decel_base = physics_config.deceleration_base if physics_config else 0.1
				var decel_speed_factor = physics_config.deceleration_speed_factor if physics_config else 0.0005
				var max_decel_factor = physics_config.max_deceleration_factor if physics_config else 0.15
			
				# Calculate friction force with material and entity properties
				var friction_force = friction * frame_rate_adj * (entity_mass * 0.8 + 0.2) # Mass affects friction but not linearly
				
				# Calculate deceleration based on physics properties
				var deceleration = friction_force * (decel_base + speed * decel_speed_factor)
				
				# Entity size affects maximum deceleration (smaller entities slow down faster)
				var size_adjusted_max_factor = max_decel_factor * (1.2 - entity_size * 0.2)
				deceleration = min(deceleration, speed * size_adjusted_max_factor)
				
				# Calculate new speed after applying friction
				var new_speed = max(0, speed - deceleration)
				
				# Set new velocity
				var new_velocity = Vector2(direction * new_speed, 0.0)
				result["velocity"] = new_velocity
				
				print("MotionSystem: Sliding with speed=", new_speed, ", deceleration=", deceleration, ", entity_mass=", entity_mass)
		else:
			# No collision material system, use default friction
			var speed = abs(velocity.x)
			var direction = sign(velocity.x)
			
			# We could use entity type here in the future for type-specific friction
			# var entity_type_for_friction = collision_info.get("entity_type", "default")
			var friction = physics_config.default_ground_friction if physics_config else default_ground_friction
			
			# Apply a physics-based deceleration
			var deceleration = friction * 2.5 * (entity_mass * 0.7 + 0.3) # Consider mass but not linearly
			var new_speed = max(0, speed - deceleration)
			
			if new_speed < stop_threshold * 2.0:
				# Use the same gradual decay approach for consistency
				var decay_rate = 0.7
				
				# Apply decay
				var decayed_speed = speed * decay_rate
				
				# Initialize final_speed variable
				var final_speed = decayed_speed
				
				if decayed_speed < 0.1:
					# Finally come to a complete stop
					result["velocity"] = Vector2.ZERO
					result["is_sliding"] = false
					print("MotionSystem: Sliding stopped naturally")
				else:
					# Continue with gradual decay
					result["velocity"] = Vector2(direction * final_speed, 0.0)
					print("MotionSystem: Sliding with decayed speed=", final_speed)
			else:
				result["velocity"] = Vector2(direction * new_speed, 0.0) # Ensure Y velocity is zero
				print("MotionSystem: Sliding with new_speed=", new_speed)
	
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
