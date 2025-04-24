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
@export var vertical_velocity_threshold: float = 10.0 # Minimum vertical speed (pixels/sec) to trigger anticipation

# Downward anticipation (when falling)
@export var downward_anticipation_factor: float = 0.65 # Multiplier specifically for downward velocity (Increase for stronger effect)
@export var max_downward_anticipation_offset: float = 620.0 # Max pixels camera will offset downwards due to anticipation (Sensible default)

# Upward anticipation (when rising)
@export var upward_anticipation_factor: float = 0.15 # Multiplier specifically for upward velocity (Negative Y)
@export var max_upward_anticipation_offset: float = 300.0 # Max pixels camera will offset upwards due to anticipation

# Look-ahead Speed Scaling (Optional Enhancement)
@export var enable_lookahead_speed_scaling: bool = false # Set to true to enable scaling below
@export var lookahead_scale_min_speed: float = 300.0 # Speed below which lookahead factor is base value
@export var lookahead_scale_max_speed: float = 1500.0 # Speed above which lookahead factor is max value
@export var lookahead_max_scale_multiplier: float = 1.5 # Multiplier applied to base lookahead factors at max speed

# --- Dynamic Zoom Configuration ---
@export_group("Dynamic Zoom")
# Note: min_zoom is visually MORE zoomed IN (e.g., 1.0), max_zoom is visually MORE zoomed OUT (e.g., 1.5)
@export var min_zoom: float = 1.0 # Default zoom level (at or below min speed)
@export var max_zoom: float = 1.5 # Maximum zoom out level (at or above max speed)
@export var zoom_min_speed_threshold: float = 200.0 # Speed below which zoom stays at min_zoom
@export var zoom_max_speed_threshold: float = 1000.0 # Speed above which zoom stays at max_zoom
@export var zoom_smoothing_speed: float = 5.0 # How quickly the zoom adjusts

# --- Slow Motion Configuration ---
@export_group("Slow Motion")
@export_range(0.01, 0.99, 0.01) var default_slowmo_factor: float = 0.5 # Default time scale (e.g., 0.5 = 50% speed)
@export var default_slowmo_duration: float = 2.0 # Default duration in seconds (real time)
