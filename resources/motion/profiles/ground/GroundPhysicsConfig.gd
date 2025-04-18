class_name GroundPhysicsConfig
extends Resource

## Unique identifier for the biome or ground type this config represents.
@export var biome_id: String = "default"

## Coefficient of friction affecting horizontal movement deceleration. (Unitless, typically >= 0)
@export_range(0.0, 1.0) var friction: float = 0.2

## Coefficient of restitution determining energy retained after a bounce. (Unitless, 0.0 to 1.0+)
@export_range(0.0, 2.0) var bounce: float = 0.8

## Coefficient representing air resistance or general velocity damping. (Unitless, typically >= 0)
@export_range(0.0, 1.0) var drag: float = 0.1

## Multiplier applied to the default gravity strength. (1.0 = default gravity)
@export_range(0.1, 2.0) var gravity_scale: float = 1.0

## Multiplier affecting how external forces interact with the player's perceived mass (e.g., knockback resistance). (1.0 = default mass)
@export var mass_multiplier: float = 1.0

## General multiplier applied to outgoing velocity changes (e.g., boosts, jumps). (1.0 = default velocity)
@export var velocity_modifier: float = 1.0

## Multiplier affecting the player's ability to influence movement while airborne. (0.0 = no control, 1.0 = default control)
@export var air_control_multiplier: float = 1.0

# Note: Custom has_property method removed. MotionProfileResolver now uses 'key in config'.
