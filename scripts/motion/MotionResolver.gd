class_name MotionResolver
extends RefCounted

# Debug flag to enable/disable debug prints
var debug_enabled: bool = false

# Resolves an array of motion modifiers into a final motion vector
# modifiers: Array of MotionModifier objects
# Returns: The final resolved Vector2
func resolve_modifiers(modifiers: Array) -> Vector2:
	# Resolve modifiers
	
	# Sort modifiers by priority (highest first)
	modifiers.sort_custom(func(a, b): return a.priority > b.priority)
	
	var final_vector = Vector2.ZERO
	var replacement_applied = false
	
	# Process replacement modifiers first (highest priority wins)
	for mod in modifiers:
		if not mod.is_additive:
			if not replacement_applied:
				# Apply replacement modifier
				final_vector = mod.vector
				replacement_applied = true
			# Skip lower priority replacement modifiers
	
	# Then process additive modifiers
	for mod in modifiers:
		if mod.is_additive:
			# Apply additive modifier
			final_vector += mod.vector
	
	# Return final vector
	
	return final_vector

# Resolves scalar modifiers (like friction multipliers)
# modifiers: Array of MotionModifier objects
# base_value: The base value to modify
# Returns: The final scalar value
func resolve_scalar_modifiers(modifiers: Array, base_value: float) -> float:
	# Resolve scalar modifiers
	
	# Sort modifiers by priority (highest first)
	modifiers.sort_custom(func(a, b): return a.priority > b.priority)
	
	var final_value = base_value
	var replacement_applied = false
	
	# Process replacement modifiers first (highest priority wins)
	for mod in modifiers:
		if not mod.is_additive:
			if not replacement_applied:
				# Apply replacement scalar modifier
				final_value = mod.scalar
				replacement_applied = true
			# Skip lower priority replacement modifiers
	
	# Then process multiplicative modifiers
	for mod in modifiers:
		if mod.is_additive:
			# Apply multiplicative scalar modifier
			final_value *= mod.scalar
	
	# Return final scalar value
	
	return final_value
