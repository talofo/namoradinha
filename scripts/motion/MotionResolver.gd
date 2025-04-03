class_name MotionResolver
extends RefCounted

# Debug flag to enable/disable debug prints
var debug_enabled: bool = false

# Resolves an array of motion modifiers into a final motion vector
# modifiers: Array of MotionModifier objects
# Returns: The final resolved Vector2
func resolve_modifiers(modifiers: Array) -> Vector2:
	if debug_enabled:
		print("[MotionResolver] Resolving %d modifiers" % modifiers.size())
		for mod in modifiers:
			print("  - %s" % mod)
	
	# Sort modifiers by priority (highest first)
	modifiers.sort_custom(func(a, b): return a.priority > b.priority)
	
	var final_vector = Vector2.ZERO
	var replacement_applied = false
	
	# Process replacement modifiers first (highest priority wins)
	for mod in modifiers:
		if not mod.is_additive:
			if not replacement_applied:
				if debug_enabled:
					print("[MotionResolver] Applying replacement modifier: %s" % mod)
				final_vector = mod.vector
				replacement_applied = true
			# Skip lower priority replacement modifiers
	
	# Then process additive modifiers
	for mod in modifiers:
		if mod.is_additive:
			if debug_enabled:
				print("[MotionResolver] Applying additive modifier: %s" % mod)
			final_vector += mod.vector
	
	if debug_enabled:
		print("[MotionResolver] Final resolved vector: %s" % final_vector)
	
	return final_vector

# Resolves scalar modifiers (like friction multipliers)
# modifiers: Array of MotionModifier objects
# base_value: The base value to modify
# Returns: The final scalar value
func resolve_scalar_modifiers(modifiers: Array, base_value: float) -> float:
	if debug_enabled:
		print("[MotionResolver] Resolving %d scalar modifiers with base value %.2f" % [modifiers.size(), base_value])
	
	# Sort modifiers by priority (highest first)
	modifiers.sort_custom(func(a, b): return a.priority > b.priority)
	
	var final_value = base_value
	var replacement_applied = false
	
	# Process replacement modifiers first (highest priority wins)
	for mod in modifiers:
		if not mod.is_additive:
			if not replacement_applied:
				if debug_enabled:
					print("[MotionResolver] Applying replacement scalar modifier: %s" % mod)
				final_value = mod.scalar
				replacement_applied = true
			# Skip lower priority replacement modifiers
	
	# Then process multiplicative modifiers
	for mod in modifiers:
		if mod.is_additive:
			if debug_enabled:
				print("[MotionResolver] Applying multiplicative scalar modifier: %s" % mod)
			final_value *= mod.scalar
	
	if debug_enabled:
		print("[MotionResolver] Final resolved scalar: %.2f" % final_value)
	
	return final_value
