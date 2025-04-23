class_name CameraConfig
extends Resource

@export var smoothing_speed: float = 8.0 # General camera follow speed
@export var vertical_smoothing_speed: float = 12.0 # Speed for vertical lock transitions
@export var ground_viewport_ratio: float = 0.8 # How much of the screen height the 'ground' occupies visually
@export var follow_height_threshold: float = 0.3 # Percentage of screen height above the locked Y before camera follows player Y
@export var default_zoom: Vector2 = Vector2.ONE

# Look-ahead configuration
@export var horizontal_lookahead_factor: float = 0.2 # Multiplier for horizontal velocity to offset camera target
@export var vertical_lookahead_factor: float = 0.1   # Multiplier for general vertical velocity to offset camera target

# Downward anticipation (when falling)
# NOTE: These defaults are used because CameraSystem creates this config with .new()
# Changes in the Inspector won't apply unless CameraSystem is modified to export the resource itself.
@export var downward_anticipation_factor: float = 0.65 # Multiplier specifically for downward velocity (Increase for stronger effect)
@export var max_downward_anticipation_offset: float = 620.0 # Max pixels camera will offset downwards due to anticipation (Sensible default)
