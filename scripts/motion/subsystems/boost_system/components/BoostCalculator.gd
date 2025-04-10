# scripts/motion/subsystems/boost_system/components/BoostCalculator.gd
# Component responsible for calculating the boost outcome based on context and type.
class_name BoostCalculator
extends RefCounted

# No need to preload classes that are globally available via class_name

# Calculates the boost outcome.
# boost_context: The BoostContext containing current state.
# boost_type: The specific boost type instance to use for calculation.
# Returns: A BoostOutcome object.
func calculate_boost(boost_context: BoostContext, boost_type) -> BoostOutcome:
	# Create a boost outcome object to store results
	var boost_outcome = BoostOutcome.new()

	# Let the specific boost type calculate the raw boost vector
	var boost_vector = boost_type.calculate_boost_vector(boost_context)

	# Check if the calculated boost vector is effectively zero
	if boost_vector.is_zero_approx():
		boost_outcome.success = false
		boost_outcome.failure_reason = "zero_boost_vector"
		return boost_outcome

	# Calculate the resulting velocity by adding the boost vector to the current velocity
	var resulting_velocity = boost_context.current_velocity + boost_vector

	# Set the outcome properties for a successful calculation
	boost_outcome.success = true
	boost_outcome.boost_vector = boost_vector
	boost_outcome.resulting_velocity = resulting_velocity

	return boost_outcome
