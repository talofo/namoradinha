class_name ContinuousMotionResolver
extends RefCounted

# Reference to the motion system core
var _core = null

# The resolver used to calculate final motion values (for dynamic modifiers)
var _motion_modifier_resolver = null

func _init(core) -> void:
	_core = core
	# Load the renamed MotionModifierResolver
	var script = load("res://scripts/motion/MotionModifierResolver.gd")
	if script:
		_motion_modifier_resolver = script.new()
		_motion_modifier_resolver.debug_enabled = core.debug_enabled
	else:
		push_error("ContinuousMotionResolver: Failed to load MotionModifierResolver script!")

# Resolve continuous motion (called every physics frame)
# delta: Time since last frame
# context: Dictionary containing motion profile, is_sliding, etc.
# subsystems: Dictionary of registered subsystems
# Returns: The final motion vector
func resolve(delta: float, context: Dictionary, subsystems: Dictionary) -> Vector2:
	var all_modifiers = []
	var is_sliding = context.get("is_sliding", false) # Extract is_sliding from context
	# var motion_profile = context.get("profile", {}) # Extract profile if needed here
	
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
	
	# Resolve the final motion vector using the modifier resolver
	if _motion_modifier_resolver and _motion_modifier_resolver.has_method("resolve_modifiers"):
		return _motion_modifier_resolver.resolve_modifiers(all_modifiers)
	else:
		push_warning("[ContinuousMotionResolver] MotionModifierResolver not available or missing resolve_modifiers method")
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
	
	# Resolve the final scalar value using the modifier resolver
	if _motion_modifier_resolver and _motion_modifier_resolver.has_method("resolve_scalar_modifiers"):
		return _motion_modifier_resolver.resolve_scalar_modifiers(all_modifiers, base_value)
	else:
		push_warning("[ContinuousMotionResolver] MotionModifierResolver not available or missing resolve_scalar_modifiers method")
		return base_value

# Set debug mode for the modifier resolver
# enabled: Whether debug mode is enabled
func set_debug_enabled(enabled: bool) -> void:
	if _motion_modifier_resolver:
		_motion_modifier_resolver.debug_enabled = enabled
