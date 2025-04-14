# Environment System

## Overview

The Environment System governs the visual identity of the game's stages. It manages ground visuals, background layers, and environmental effects like fog or particles. Its role is to present the visual theming of each stage or chunk as determined by gameplay systems, without directly influencing gameplay logic.

This system follows a Separated but Coordinated architecture. It integrates with the Stage Composition System by responding to shared configuration and runtime signals (e.g., biome/theme changes) and updating the environment visuals accordingly.

## Architecture

The Environment System consists of several key components:

### Core Components

1. **EnvironmentSystem** (`scripts/environment/EnvironmentSystem.gd`)
   - Main coordinator that manages the visual aspects of the environment
   - Handles theme and biome changes
   - Coordinates transitions between visual states
   - Connects to global signals for stage loading and theme/biome changes

2. **GroundVisualManager** (`scripts/environment/managers/GroundVisualManager.gd`)
   - Manages ground visuals based on themes
   - Applies textures and tints to ground sprites
   - Handles transitions between ground visual states
   - Provides fallback visuals when assets are missing

3. **BackgroundManager** (`scripts/environment/managers/BackgroundManager.gd`)
   - Manages background layers with parallax support
   - Supports multiple background layers (far, mid, near)
   - Handles transitions between background visual states
   - Provides fallback visuals when assets are missing

4. **EffectsManager** (`scripts/environment/managers/EffectsManager.gd`)
   - Manages visual effects like fog, particles, and overlays
   - Creates and removes effects based on theme configuration
   - Handles transitions between effect states
   - Supports different effect types (fog, particles, overlay)

### Supporting Components

5. **ThemeDatabase** (`resources/environment/ThemeDatabase.gd`)
   - Stores and provides access to environment themes
   - Maps theme IDs to EnvironmentTheme resources

6. **EnvironmentTheme** (`resources/environment/EnvironmentTheme.gd`)
   - Defines visual properties for a specific theme
   - Includes textures, colors, and effect settings
   - Used to configure the visual appearance of the environment

7. **StageConfig** (`resources/environment/StageConfig.gd`)
   - Defines stage-specific configurations
   - Includes theme and biome IDs
   - Used to configure the environment for a specific stage

8. **TransitionHelper** (`scripts/environment/utils/TransitionHelper.gd`)
   - Provides utility functions for smooth transitions
   - Handles fading and other visual transitions

9. **EnvironmentDebugOverlay** (`scripts/environment/debug/EnvironmentDebugOverlay.gd`)
   - Provides debugging capabilities
   - Displays current theme and biome information
   - Allows manual theme switching for testing

## Signal Flow

The Environment System responds to the following signals:

- `GlobalSignals.stage_loaded(config)` - When a new stage is loaded
- `GlobalSignals.theme_changed(theme_id)` - When the theme is changed
- `GlobalSignals.biome_changed(biome_id)` - When the biome is changed
- `ground_tiles_created(ground_data)` - When ground tiles are created by the physics GroundManager

The Environment System emits the following signals:

- `visuals_updated(theme_id, biome_id)` - When visuals are updated
- `transition_completed` - When a visual transition is completed
- `fallback_activated(manager_name, reason)` - When a fallback visual is activated

## Usage

### Basic Setup

1. Add the `EnvironmentSystem.tscn` scene to your stage or game scene.
2. Assign a `ThemeDatabase` resource to the `theme_database` property.
3. Connect the appropriate signals from your stage manager or game controller.

```gdscript
# In your game or stage setup code
var environment_system = preload("res://environment/EnvironmentSystem.tscn").instantiate()
environment_system.theme_database = preload("res://resources/environment/theme_database.tres")
add_child(environment_system)

# Connect to signals if needed
environment_system.visuals_updated.connect(_on_environment_visuals_updated)
environment_system.transition_completed.connect(_on_environment_transition_completed)
environment_system.fallback_activated.connect(_on_environment_fallback_activated)
```

### Changing Themes

To change the current theme:

```gdscript
# Using the GlobalSignals singleton
GlobalSignals.theme_changed.emit("forest")

# Or directly through the EnvironmentSystem
environment_system.apply_theme_by_id("forest")
```

### Changing Biomes

To change the current biome:

```gdscript
# Using the GlobalSignals singleton
GlobalSignals.biome_changed.emit("desert")

# Or directly through the EnvironmentSystem
environment_system.change_biome("desert")
```

### Applying Stage Configuration

To apply a stage configuration:

```gdscript
# Create a StageConfig
var config = StageConfig.new()
config.stage_id = 1
config.theme_id = "forest"
config.biome_id = "forest"

# Using the GlobalSignals singleton
GlobalSignals.stage_loaded.emit(config)

# Or directly through the EnvironmentSystem
environment_system.apply_stage_config(config)
```

### Creating Custom Themes

To create a custom theme:

1. Create a new `EnvironmentTheme` resource.
2. Set the theme properties (textures, colors, effects).
3. Add the theme to the `ThemeDatabase`.

```gdscript
# Create a new theme
var theme = EnvironmentTheme.new()
theme.theme_id = "custom_theme"
theme.ground_texture = preload("res://path/to/ground_texture.png")
theme.ground_tint = Color(0.8, 0.8, 0.8)
theme.background_far_texture = preload("res://path/to/background_far.png")
theme.background_mid_texture = preload("res://path/to/background_mid.png")
theme.background_near_texture = preload("res://path/to/background_near.png")
theme.background_tint = Color(1.0, 1.0, 1.0)
theme.enable_effects = true
theme.effect_type = "fog"

# Add the theme to the database
theme_database.themes["custom_theme"] = theme
```

## Debugging

The Environment System includes debugging capabilities through the `EnvironmentDebugOverlay`. This overlay displays the current theme and biome information and allows manual theme switching for testing.

To enable the debug overlay:

1. Set the `debug_mode` property of the `EnvironmentSystem` to `true`.
2. The overlay will be automatically added in debug builds.

You can also manually switch themes in debug mode using keyboard shortcuts:
- `KEY_1` - Switch to the "default" theme
- `KEY_2` - Switch to the "debug" theme

## Fallback Handling

The Environment System includes fallback handling for missing assets. If a texture or other asset is missing, the system will display a fallback visual (e.g., a magenta rectangle for missing ground textures) and emit the `fallback_activated` signal with information about the missing asset.

## Testing

The Environment System includes comprehensive tests in the `scripts/environment/tests` directory:

- `test_environment_system.gd` - Tests the main EnvironmentSystem
- `test_ground_visual_manager.gd` - Tests the GroundVisualManager
- `test_background_manager.gd` - Tests the BackgroundManager
- `test_effects_manager.gd` - Tests the EffectsManager
- `test_environment_integration.gd` - Tests the integration between components

To run the tests:

```bash
./scripts/environment/tests/run_environment_tests.gd
```

## Future Expansion

The Environment System is designed for future expansion with support for:

- More complex parallax backgrounds
- Time-of-day settings
- Weather effects
- Biome sequencing across chunks
- More advanced visual effects

The modular design allows for easy extension and enhancement of the visual capabilities without affecting gameplay logic.
