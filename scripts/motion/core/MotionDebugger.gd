class_name MotionDebugger
extends RefCounted

# Reference to the motion system core
var _core = null

# Debug flag to enable/disable debug prints (disabled by default)
var debug_enabled: bool = false

func _init(core) -> void:
	_core = core

# Enable or disable debug prints
# enabled: Whether debug mode is enabled
func set_debug_enabled(enabled: bool) -> void:
	debug_enabled = enabled

# Log a debug message
# message: The message to log
# category: The category of the message (e.g., "physics", "collision")
func log(message: String, category: String = "general") -> void:
	if not debug_enabled:
		return
	
	print("[MotionDebugger:%s] %s" % [category, message])

# Log a vector
# name: The name of the vector
# vector: The vector to log
# category: The category of the message (e.g., "physics", "collision")
func log_vector(name: String, vector: Vector2, category: String = "vector") -> void:
	if not debug_enabled:
		return
	
	print("[MotionDebugger:%s] %s = %s (magnitude = %.2f)" % [
		category, 
		name, 
		vector, 
		vector.length()
	])

# Log a scalar value
# name: The name of the scalar
# value: The scalar value to log
# category: The category of the message (e.g., "physics", "collision")
func log_scalar(name: String, value: float, category: String = "scalar") -> void:
	if not debug_enabled:
		return
	
	print("[MotionDebugger:%s] %s = %.2f" % [category, name, value])

# Log a state change
# old_state: The old state
# new_state: The new state
# entity_id: The ID of the entity
func log_state_change(old_state: Dictionary, new_state: Dictionary, entity_id: int) -> void:
	if not debug_enabled:
		return
	
	var state_changes = []
	
	for key in new_state:
		if not old_state.has(key) or old_state[key] != new_state[key]:
			var old_value = old_state.get(key, "N/A")
			var new_value = new_state[key]
			state_changes.append("%s: %s -> %s" % [key, old_value, new_value])
	
	if state_changes.size() > 0:
		print("[MotionDebugger:state] Entity %d state changes:" % entity_id)
		for change in state_changes:
			print("  - %s" % change)

# Log subsystem registration
# subsystem_name: The name of the subsystem
func log_subsystem_registration(subsystem_name: String) -> void:
	if not debug_enabled:
		return
	
	print("[MotionDebugger:subsystem] Registered subsystem: %s" % subsystem_name)

# Log subsystem unregistration
# subsystem_name: The name of the subsystem
func log_subsystem_unregistration(subsystem_name: String) -> void:
	if not debug_enabled:
		return
	
	print("[MotionDebugger:subsystem] Unregistered subsystem: %s" % subsystem_name)
