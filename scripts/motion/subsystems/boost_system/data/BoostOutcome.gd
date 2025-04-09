# scripts/motion/subsystems/boost_system/data/BoostOutcome.gd
# Output data structure for boost calculation results.
class_name BoostOutcome
extends RefCounted

var success: bool = false
var failure_reason: String = "" # e.g., "not_airborne", "unknown_boost_type", "zero_boost_vector"
var boost_vector: Vector2 = Vector2.ZERO # The calculated velocity change to apply
var resulting_velocity: Vector2 = Vector2.ZERO # The predicted velocity after applying the boost
