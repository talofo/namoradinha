class_name ThemeDatabase
extends Resource

@export var themes: Dictionary = {
    "default": null,  # Will be set to preload("res://resources/environment/themes/default_theme.tres")
    "debug": null     # Will be set to preload("res://resources/environment/themes/debug_theme.tres")
}

# Visual background theme configurations
@export var visual_background_themes: Dictionary = {
    "default": null,  # Will be set to visual background theme config
    "debug": null     # Will be set to visual background theme config
}

func get_theme(theme_id: String) -> EnvironmentTheme:
    if themes.has(theme_id):
        return themes[theme_id]
    return themes.get("debug", null)

func get_visual_background_theme(theme_id: String) -> EnvironmentThemeConfig:
    if visual_background_themes.has(theme_id):
        return visual_background_themes[theme_id]
    return visual_background_themes.get("debug", null)
