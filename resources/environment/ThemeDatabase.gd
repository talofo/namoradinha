class_name ThemeDatabase
extends Resource

@export var themes: Dictionary = {
    "default": null,  # Will be set to preload("res://resources/environment/themes/default_theme.tres")
    "debug": null     # Will be set to preload("res://resources/environment/themes/debug_theme.tres")
}

func get_theme(theme_id: String) -> EnvironmentTheme:
    if themes.has(theme_id):
        return themes[theme_id]
    return themes.get("debug", null)
