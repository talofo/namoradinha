# scripts/motion/subsystems/boost_system/BoostSystem.gd
# Main entry point for the Boost System subsystem.
# Handles boost requests, delegates to specific boost types, and applies results.
class_name BoostSystem
extends RefCounted
# Implicitly implements IMotionSubsystem (ensure methods match the interface)

const MotionProfileResolver = preload("res://scripts/motion/core/MotionProfileResolver.gd")

# Signals
signal boost_applied(entity_id: int, boost_vector: Vector2, boost_type: String)

# No need to preload classes that are globally available via class_name
# Assuming IMotionSubsystem is defined globally or preloaded elsewhere if needed directly.

# Components
var _boost_calculator: BoostCalculator = null
var _boost_type_registry: BoostTypeRegistry = null
var _motion_profile_resolver: MotionProfileResolver = null # Added resolver reference

# Configuration (Old - to be removed or adapted)
# var _physics_config = null # Will be set via set_physics_config

# Initialization logic
func _init() -> void:
	_boost_calculator = BoostCalculator.new()
	_boost_type_registry = BoostTypeRegistry.new()

	# Register the initial boost types
	var manual_air_boost = ManualAirBoost.new()
	_boost_type_registry.register_boost_type("manual_air", manual_air_boost)
	# Register other boost types here in the future

# --- Configuration (Old - keep method signature for now if called elsewhere, but deprecate) ---

# Sets the physics configuration resource used by boost types.
# physics_config: The loaded PhysicsConfig resource.
# @deprecated Use MotionProfileResolver instead.
func set_physics_config(_physics_config) -> void:
	# _physics_config = physics_config # No longer storing this directly
	push_warning("BoostSystem: set_physics_config is deprecated. Use MotionProfileResolver.")
	pass

# --- Core Logic ---

# Attempts to apply a boost of a specific type to an entity.
# entity_id: The ID of the entity requesting the boost.
# boost_type: The string identifier of the boost type (e.g., "manual_air").
# state_data: A Dictionary containing the entity's current motion state
#             (e.g., {"is_airborne": bool, "is_rising": bool, "velocity": Vector2, "position": Vector2}).
# direction: An optional Vector2 hint for directional boosts (not used by ManualAirBoost).
# Returns: A Dictionary containing the result:
#          {"success": bool, "reason": String (if failed),
#           "boost_vector": Vector2 (if successful), "resulting_velocity": Vector2 (if successful)}
func try_apply_boost(entity_id: int, boost_type: String, state_data: Dictionary, direction: Vector2 = Vector2.ZERO) -> Dictionary:
	# --- Input Validation ---
	var player_node = state_data.get("player_node", null)
	if not is_instance_valid(player_node):
		push_error("BoostSystem: 'player_node' missing or invalid in state_data for try_apply_boost.")
		return {"success": false, "reason": "missing_player_node"}

	# 1. Check if the requested boost type is registered
	if not _boost_type_registry.has_boost_type(boost_type):
		push_warning("BoostSystem: Unknown boost type requested: '%s' for entity %d" % [boost_type, entity_id])
		return {"success": false, "reason": "unknown_boost_type"}

	# 2. Resolve Motion Profile
	var motion_profile = {}
	if _motion_profile_resolver:
		motion_profile = _motion_profile_resolver.resolve_motion_profile(player_node)
	else:
		motion_profile = MotionProfileResolver.DEFAULTS.duplicate()
		push_warning("BoostSystem: MotionProfileResolver not available.")

	# 3. Create the context object for this boost attempt
	var boost_context = BoostContext.new()
	boost_context.entity_id = entity_id
	boost_context.player_node = player_node # Pass the node itself if needed by calculator/types
	# Safely get values from state_data, providing defaults
	boost_context.is_airborne = state_data.get("is_airborne", false)
	boost_context.is_rising = state_data.get("is_rising", false)
	boost_context.current_velocity = state_data.get("velocity", Vector2.ZERO)
	boost_context.position = state_data.get("position", Vector2.ZERO)
	boost_context.requested_direction = direction
	# boost_context.physics_config = _physics_config # Removed old config
	boost_context.motion_profile = motion_profile # Pass the resolved profile

	# 4. Get the specific boost type handler instance
	var boost_type_instance = _boost_type_registry.get_boost_type(boost_type)

	# 5. Check if the boost type's conditions are met
	if not boost_type_instance.can_apply_boost(boost_context):
		# This is an expected outcome, not necessarily an error (e.g., trying to air boost on ground)
		# push_warning("BoostSystem: Boost type '%s' cannot be applied in current state for entity %d" % [boost_type, entity_id])
		return {"success": false, "reason": "invalid_state_for_boost"}

	# 6. Calculate the boost outcome using the calculator and type instance
	var boost_outcome: BoostOutcome = _boost_calculator.calculate_boost(boost_context, boost_type_instance)

	# 7. Check if the calculation was successful (e.g., didn't result in zero vector)
	if not boost_outcome.success:
		# push_warning("BoostSystem: Boost calculation failed for type '%s', entity %d. Reason: %s" % [boost_type, entity_id, boost_outcome.failure_reason])
		return {"success": false, "reason": boost_outcome.failure_reason}

	# 8. Emit signal indicating a successful boost application
	emit_signal("boost_applied", entity_id, boost_outcome.boost_vector, boost_type)

	# 9. Return the successful result
	return {
		"success": true,
		"boost_vector": boost_outcome.boost_vector,
		"resulting_velocity": boost_outcome.resulting_velocity
	}


# --- IMotionSubsystem Interface Implementation ---

# Returns the unique name of this subsystem.
func get_name() -> String:
	return "BoostSystem" # Use the standard name now

# Called when the subsystem is registered with the MotionSystemCore.
func on_register() -> void:
	# Perform any setup needed upon registration (e.g., connecting signals)
	pass

# Called when the subsystem is unregistered.
func on_unregister() -> void:
	# Perform any cleanup needed upon unregistration
	pass

# Returns motion modifiers for continuous application (e.g., gravity, friction).
# This system applies instantaneous boosts, so it returns none.
func get_motion_modifiers(_entity_id: int, _delta: float) -> Array:
	return []

# Returns motion modifiers triggered by collisions.
# This system doesn't react directly to collisions in this way.
func get_collision_modifiers(_collision_context) -> Array:
	# collision_context likely contains info about the collision (entity_id, collider, normal, etc.)
	return []

# Declares signals provided by this subsystem.
func get_provided_signals() -> Dictionary:
	# Format: { "signal_name": [arg_type1, arg_type2, ...] }
	# Using strings for types as per potential MotionSystemCore conventions
	return {
		"boost_applied": ["int", "Vector2", "String"]
	}

# Declares signals this subsystem depends on from other subsystems.
func get_signal_dependencies() -> Array:
	# Format: [{ "provider": "SubsystemName", "signal_name": "signal_name", "method": "local_method_to_call" }]
	# This system currently doesn't depend on signals from others.
	return []


# --- Resolver Integration ---

## Called by Game.gd (or MotionSystemCore) to provide the resolver instance.
func initialize_with_resolver(resolver: MotionProfileResolver) -> void:
	_motion_profile_resolver = resolver
	# Optionally print debug message if needed
	# print("BoostSystem: MotionProfileResolver initialized.")
