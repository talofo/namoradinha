# scripts/motion/subsystems/obstacle_system/data/ObstacleOutcome.gd
# Output data structure for obstacle calculation results.
class_name ObstacleOutcome
extends RefCounted

enum OutcomeType { MODIFIED, STOPPED, UNAFFECTED }

var outcome_type: int = OutcomeType.UNAFFECTED
var original_velocity: Vector2 = Vector2.ZERO
var resulting_velocity: Vector2 = Vector2.ZERO
var applied_effects: Array = [] # Names of effects that were applied
var gravity_scale_modifier: float = 1.0 # For future arc shaping
var trajectory_angle_modifier: float = 0.0 # For future trajectory modification
var debug_data: ObstacleDebugData = null

# Initialize with original velocity
func _init(velocity: Vector2 = Vector2.ZERO) -> void:
	original_velocity = velocity
	resulting_velocity = velocity
	debug_data = ObstacleDebugData.new()

# Mark as modified with new velocity
func set_modified(new_velocity: Vector2) -> void:
	resulting_velocity = new_velocity
	outcome_type = OutcomeType.MODIFIED

# Mark as stopped
func set_stopped() -> void:
	resulting_velocity = Vector2.ZERO
	outcome_type = OutcomeType.STOPPED

# Add an applied effect
func add_effect(effect_name: String) -> void:
	applied_effects.append(effect_name)
	
# Set gravity scale modifier
func set_gravity_scale(scale: float) -> void:
	gravity_scale_modifier = scale
	
# Set trajectory angle modifier
func set_trajectory_angle(angle: float) -> void:
	trajectory_angle_modifier = angle
