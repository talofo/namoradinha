class_name BounceOutcome
extends RefCounted

const BounceDebugDataClass = preload("res://scripts/motion/subsystems/bounce_system/data/BounceDebugData.gd")

## Represents the result of a bounce calculation.

# Enum-like constants for termination states
const STATE_BOUNCING = "BOUNCING"
const STATE_SLIDING = "SLIDING"
const STATE_STOPPED = "STOPPED"

# The calculated velocity vector immediately after the bounce/impact resolution.
# If termination_state is SLIDING or STOPPED, this represents the velocity entering that state.
var new_velocity: Vector2 = Vector2.ZERO

# The state after the impact. Use constants defined above (STATE_BOUNCING, STATE_SLIDING, STATE_STOPPED).
var termination_state: String = STATE_BOUNCING

# Optional debug information, populated only in debug builds/editor.
var debug_data: BounceDebugData = null

func _init(p_new_velocity: Vector2 = Vector2.ZERO, p_termination_state: String = STATE_BOUNCING, p_debug_data: BounceDebugData = null) -> void:
	new_velocity = p_new_velocity
	termination_state = p_termination_state
	debug_data = p_debug_data

func is_terminated() -> bool:
	return termination_state != STATE_BOUNCING

func _to_string() -> String:
	var debug_str = ""
	if debug_data != null:
		debug_str = " | Debug: %s" % str(debug_data)
		
	return "BounceOutcome { State: %s, Velocity: %s%s }" % [termination_state, str(new_velocity), debug_str]
