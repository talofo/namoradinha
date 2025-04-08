class_name BounceDebugData
extends RefCounted

## Optional data structure holding debug information about a bounce calculation.
## Populated only in debug builds or when explicitly enabled.

# Reason for termination, if applicable (e.g., "Velocity below threshold", "Friction stop").
var termination_reason: String = ""

# Calculated velocity components before applying final modifiers or clamping.
var calculated_velocity_pre_mods: Vector2 = Vector2.ZERO

# Effective elasticity used in calculation (surface * profile multiplier).
var effective_elasticity: float = 0.0

# Effective friction used in calculation (surface * profile multiplier).
var effective_friction: float = 0.0

# Any other internal values useful for debugging the calculation.
var internal_notes: Array[String] = []

func add_note(note: String) -> void:
	internal_notes.append(note)

func _to_string() -> String:
	var parts = []
	if not termination_reason.is_empty():
		parts.append("Termination Reason: %s" % termination_reason)
	parts.append("Pre-Mod Velocity: %s" % str(calculated_velocity_pre_mods))
	parts.append("Effective Elasticity: %.3f" % effective_elasticity)
	parts.append("Effective Friction: %.3f" % effective_friction)
	if not internal_notes.is_empty():
		parts.append("Notes: [%s]" % ", ".join(internal_notes))
	return "BounceDebugData { %s }" % ", ".join(parts)
