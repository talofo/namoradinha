class_name ContinuousMotionResolver
extends RefCounted

# Reference to the motion system core
var _core = null

# The resolver used to calculate final motion values
var _resolver = null

func _init(core) -> void:
	_core = core
	_resolver = load("res://scripts/motion/MotionResolver.gd").new()
	_resolver.debug_enabled = core.debug_enabled

# Resolve continuous motion (called every physics frame)
# delta: Time since last frame
# is_sliding: Whether the entity is currently sliding
# subsystems: Dictionary of registered subsystems
# Returns: The final motion vector
func resolve(delta: float, is_sliding: bool, subsystems: Dictionary) -> Vector2:
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in subsystems:
		var subsystem = subsystems[subsystem_name]
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
	if _resolver and _resolver.has_method("resolve_modifiers"):
		return _resolver.resolve_modifiers(all_modifiers)
	else:
		push_warning("[ContinuousMotionResolver] Resolver not available or missing resolve_modifiers method")
		return Vector2.ZERO

# Resolve a scalar value (like friction) with modifiers from all subsystems
# type: The type of scalar to resolve (e.g., "friction", "bounce")
# base_value: The base value to modify
# subsystems: Dictionary of registered subsystems
# Returns: The final scalar value
func resolve_scalar(type: String, base_value: float, subsystems: Dictionary) -> float:
	var all_modifiers = []
	
	# Collect modifiers from all subsystems
	for subsystem_name in subsystems:
		var subsystem = subsystems[subsystem_name]
		if subsystem.has_method("get_continuous_modifiers"):
			var continuous_modifiers = subsystem.get_continuous_modifiers(0.0)
			
			# Filter for modifiers of the specified type
			for mod in continuous_modifiers:
				if mod.has("type") and mod.type == type:
					all_modifiers.append(mod)
	
	# Resolve the final scalar value
	if _resolver and _resolver.has_method("resolve_scalar_modifiers"):
		return _resolver.resolve_scalar_modifiers(all_modifiers, base_value)
	else:
		push_warning("[ContinuousMotionResolver] Resolver not available or missing resolve_scalar_modifiers method")
		return base_value

# Set debug mode
# enabled: Whether debug mode is enabled
func set_debug_enabled(enabled: bool) -> void:
	if _resolver:
		_resolver.debug_enabled = enabled
