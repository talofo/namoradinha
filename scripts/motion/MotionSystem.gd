class_name MotionSystem
extends Node

signal subsystem_registered(subsystem_name: String)
signal subsystem_unregistered(subsystem_name: String)

# The resolver used to calculate final motion values
var resolver = null # Will be MotionResolver

# Dictionary of registered subsystems
var _subsystems: Dictionary = {}

# Debug flag to enable/disable debug prints
var debug_enabled: bool = false

func _init() -> void:
	resolver = load("res://scripts/motion/MotionResolver.gd").new()

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
	var name = subsystem.get_name()
	
	if _subsystems.has(name):
		push_warning("[MotionSystem] Subsystem '%s' is already registered" % name)
		return false
	
	_subsystems[name] = subsystem
	subsystem.on_register()
	
	if debug_enabled:
		print("[MotionSystem] Registered subsystem: %s" % name)
	
	subsystem_registered.emit(name)
	return true

# Unregister a subsystem from the motion system
# name: The name of the subsystem to unregister
# Returns: True if unregistration was successful, false otherwise
func unregister_subsystem(name: String) -> bool:
	if not _subsystems.has(name):
		push_warning("[MotionSystem] Subsystem '%s' is not registered" % name)
		return false
	
	var subsystem = _subsystems[name]
	subsystem.on_unregister()
	_subsystems.erase(name)
	
	if debug_enabled:
		print("[MotionSystem] Unregistered subsystem: %s" % name)
	
	subsystem_unregistered.emit(name)
	return true

# Get a registered subsystem by name
# name: The name of the subsystem to get
# Returns: The subsystem, or null if not found
func get_subsystem(name: String):
	return _subsystems.get(name)

# Get all registered subsystems
# Returns: Dictionary of subsystems (name -> subsystem)
func get_all_subsystems() -> Dictionary:
	return _subsystems.duplicate()

# Resolve continuous motion (called every physics frame)
# delta: Time since last frame
# Returns: The final motion vector
func resolve_continuous_motion(delta: float) -> Vector2:
	if debug_enabled:
		print("[MotionSystem] Resolving continuous motion (delta: %.3f)" % delta)
	
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in _subsystems:
		var subsystem = _subsystems[subsystem_name]
		var modifiers = subsystem.get_continuous_modifiers(delta)
		
		if debug_enabled:
			print("[MotionSystem] Collected %d modifiers from %s" % [modifiers.size(), subsystem_name])
		
		all_modifiers.append_array(modifiers)
	
	# Resolve the final motion vector
	return resolver.resolve_modifiers(all_modifiers)

# Resolve collision motion (called when a collision occurs)
# collision_info: Information about the collision
# Returns: The final motion vector
func resolve_collision_motion(collision_info: Dictionary) -> Vector2:
	if debug_enabled:
		print("[MotionSystem] Resolving collision motion")
	
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in _subsystems:
		var subsystem = _subsystems[subsystem_name]
		var modifiers = subsystem.get_collision_modifiers(collision_info)
		
		if debug_enabled:
			print("[MotionSystem] Collected %d modifiers from %s" % [modifiers.size(), subsystem_name])
		
		all_modifiers.append_array(modifiers)
	
	# Resolve the final motion vector
	return resolver.resolve_modifiers(all_modifiers)

# Resolve a scalar value (like friction) with modifiers from all subsystems
# type: The type of scalar to resolve (e.g., "friction", "bounce")
# base_value: The base value to modify
# Returns: The final scalar value
func resolve_scalar(type: String, base_value: float) -> float:
	if debug_enabled:
		print("[MotionSystem] Resolving scalar '%s' with base value %.2f" % [type, base_value])
	
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in _subsystems:
		var subsystem = _subsystems[subsystem_name]
		var continuous_modifiers = subsystem.get_continuous_modifiers(0.0)
		
		# Filter for modifiers of the specified type
		for mod in continuous_modifiers:
			if mod.type == type:
				all_modifiers.append(mod)
	
	# Resolve the final scalar value
	return resolver.resolve_scalar_modifiers(all_modifiers, base_value)
