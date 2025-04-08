class_name BounceSystem
extends RefCounted
#warning-ignore-all:unused_class_variable # Interface methods might not use all variables

# Note: Preloads removed as classes are globally available via class_name

# --- Constants ---
# Threshold for considering a collision normal as "floor" (dot product with UP vector)
const FLOOR_NORMAL_THRESHOLD = 0.7 

# --- Private Variables ---
var _calculator: BounceCalculator = null

# --- Initialization ---
func _init() -> void:
	_calculator = BounceCalculator.new()

# --- IMotionSubsystem Implementation ---

func get_name() -> String:
	return "BounceSystem"

func on_register() -> void:
	# No setup needed on registration in this stateless design
	pass

func on_unregister() -> void:
	# No cleanup needed on unregistration
	pass

func get_continuous_modifiers(_delta: float) -> Array[MotionModifier]:
	# Bounce system is purely reactive to collisions, no continuous modifiers.
	return []

# Updated to accept CollisionContext directly
func get_collision_modifiers(context: CollisionContext) -> Array[MotionModifier]:
	var modifiers: Array[MotionModifier] = []

	# --- Input Validation ---
	if not context or not context.incoming_motion_state or not context.impact_surface_data or not context.player_bounce_profile:
		printerr("BounceSystem: Invalid or incomplete CollisionContext received.")
		return modifiers

	# Check if it's a floor collision based on the normal in the context
	var normal: Vector2 = context.impact_surface_data.normal
	# If the upward component of the normal (dot product with UP) is less than the threshold,
	# it's considered a wall or ceiling, not a floor.
	if normal.dot(Vector2.UP) < FLOOR_NORMAL_THRESHOLD: 
		# Not a floor collision (or slope is too steep to be considered floor)
		return modifiers
	
	# Context is already provided.
	
	# --- Perform Calculation ---
	# Ensure generate_debug_data flag is set correctly based on engine state
	# (The context object passed in might have it set differently by the caller,
	# but we override here for consistency within the subsystem call)
	context.generate_debug_data = Engine.is_editor_hint() or OS.is_debug_build()
	
	var outcome: BounceOutcome = _calculator.calculate(context)

	# --- Handle Outcome ---
	if outcome:
		# Log debug info if available
		if outcome.debug_data:
			print("BounceSystem Debug: ", outcome.debug_data)

		# Create a modifier to apply the calculated velocity
		# Priority should be high to override other collision responses if bouncing/sliding.
		var velocity_modifier = MotionModifier.new(
			get_name(),           # source
			"velocity",           # type
			20,                   # priority (high)
			outcome.new_velocity, # vector (calculated bounce/slide/stop response)
			1.0,                  # scalar (unused for velocity)
			false,                # is_additive (replace velocity)
			-1                    # duration (instantaneous change)
		)
		modifiers.append(velocity_modifier)
		
		# Potentially emit signals based on outcome.termination_state here if needed
		# e.g., if outcome.is_terminated(): emit_signal("bounce_terminated", entity_id, outcome.termination_state)
		# e.g., if outcome.termination_state == BounceOutcome.STATE_BOUNCING: emit_signal("bounce_occurred", entity_id)

	return modifiers


func get_provided_signals() -> Dictionary:
	# Example: Define signals if needed for effects
	# return {
	# 	"bounce_occurred": ["int"], # entity_id
	# 	"bounce_terminated": ["int", "String"] # entity_id, termination_state
	# }
	return {}

func get_signal_dependencies() -> Array:
	# This system doesn't depend on signals from other subsystems in this design.
	return []
