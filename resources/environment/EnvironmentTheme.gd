class_name EnvironmentTheme
extends Resource

@export var theme_id: String = "default"

@export_category("Ground")
@export var ground_texture: Texture2D
@export var ground_tint: Color = Color.WHITE

@export_category("Background")
@export var background_far_texture: Texture2D
@export var background_mid_texture: Texture2D
@export var background_near_texture: Texture2D
@export var use_single_background: bool = true  # If true, only background_far_texture is used for all layers
@export var background_tint: Color = Color.WHITE
@export var parallax_ratio: Vector2 = Vector2(0.5, 0.5)

@export_category("Effects")
@export var enable_effects: bool = false
@export var effect_type: String = ""
@export var effect_scene: PackedScene
