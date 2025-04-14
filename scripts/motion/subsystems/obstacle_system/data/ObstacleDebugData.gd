# scripts/motion/subsystems/obstacle_system/data/ObstacleDebugData.gd
# Debug data structure for obstacle calculations.
class_name ObstacleDebugData
extends RefCounted

var obstacle_name: String = ""
var obstacle_type: String = ""
var effect_logs: Array = []
var calculation_steps: Array = []

# Add a log entry for an effect
func log_effect(effect_name: String, message: String) -> void:
	effect_logs.append("[%s] %s" % [effect_name, message])
	
# Add a calculation step
func add_calculation_step(step_name: String, value) -> void:
	calculation_steps.append({
		"step": step_name,
		"value": value
	})
	
# Get a formatted debug string
func get_debug_string() -> String:
	var debug_str = "Obstacle Hit: %s (%s)\n" % [obstacle_name, obstacle_type]
	
	for log_entry in effect_logs:
		debug_str += log_entry + "\n"
		
	for step in calculation_steps:
		debug_str += "- %s: %s\n" % [step.step, step.value]
		
	return debug_str
