extends Node

# Dictionary to store per-system debug flags
var debug_flags: Dictionary = {
    "STAGE": false,
    "MOTION": false,
    "BACKGROUND": false,
    "CAMERA": false,
    "ENVIRONMENT": false
}

# Global debug toggle that affects all systems
var debug_enabled: bool = false

func _ready() -> void:
    # Initialize with debug enabled in debug builds
    debug_enabled = OS.is_debug_build()
    if debug_enabled:
        # Enable all systems in debug builds by default
        toggle_all(true)

# Toggle debug for all systems
func toggle_all(enabled: bool) -> void:
    debug_enabled = enabled
    for key in debug_flags.keys():
        debug_flags[key] = enabled

# Toggle debug for a specific system
func toggle_system(system_tag: String, enabled: bool) -> void:
    if debug_flags.has(system_tag):
        debug_flags[system_tag] = enabled

# Main debug print function
func print(system_tag: String, message: String, variable = null) -> void:
    if not debug_enabled or not debug_flags.get(system_tag, false):
        return
        
    var output = "[%s] %s" % [system_tag, message]
    if variable != null:
        output += " " + str(variable)
    
    print_rich("[color=yellow]" + output + "[/color]")

# Convenience function to check if debug is enabled for a system
func is_system_enabled(system_tag: String) -> bool:
    return debug_enabled and debug_flags.get(system_tag, false)
