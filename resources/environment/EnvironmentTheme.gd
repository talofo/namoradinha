class_name EnvironmentTheme
extends Resource

@export var theme_id: String = "default"

@export_category("Ground")
@export var ground_texture: Texture2D
@export var ground_tint: Color = Color.WHITE

@export_category("Effects")
@export var enable_effects: bool = false
@export var effect_type: String = ""
@export var effect_scene: PackedScene
