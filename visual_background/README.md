# Visual Background System

## Overview

The Visual Background System provides a modular, data-driven parallax background architecture for the game. It enables dynamic, theme-based multi-layer backgrounds with performance monitoring and seamless integration with the EnvironmentSystem and CameraManager.

- **Data-driven:** All background composition is defined via resource files.
- **Modular:** Each responsibility is encapsulated in a focused class or resource.
- **Extensible:** Designed for future expansion (atmospherics, transitions, cinematic props).

---

## Responsibilities

- Orchestrate loading and switching of background themes in response to environment changes.
- Dynamically build and manage parallax layers and their visual elements.
- Integrate with camera movement for parallax scrolling.
- Monitor and warn about performance (layer count, texture memory, draw calls).

---

## Main Components

### VisualBackgroundSystem (Node2D)
- Entry point for the system.
- Listens for theme changes from `EnvironmentSystem`.
- Passes theme config to `ParallaxLayerController`.
- Receives camera updates and forwards to controller.

### ParallaxLayerController (ParallaxBackground)
- Manages creation and clearing of `ParallaxLayer` nodes.
- Instantiates and configures `Sprite2D` elements per layer.
- Handles tiling, scaling, modulate, and z-index for each element.
- Tracks performance metrics.

### Resource Types
- **BackgroundLayerElement.gd:** Defines a single visual element (texture, offset, scale, tiling, etc).
- **BackgroundLayerConfig.gd:** Defines a parallax layer (parallax ratio, z-index, elements).
- **EnvironmentThemeConfig.gd:** Defines a full background theme (name, array of layers).

---

## Integration

- **EnvironmentSystem:** Triggers theme changes; system listens for `visuals_updated` signal.
- **ThemeDatabase:** Stores and provides `EnvironmentThemeConfig` resources for each theme.
- **CameraManager:** Provides camera position updates for parallax effect.

---

## Usage

### Adding/Modifying Background Themes

1. Create a new `.tres` resource using `EnvironmentThemeConfig.gd`.
2. Define one or more `BackgroundLayerConfig` resources, each with an array of `BackgroundLayerElement` resources.
3. Assign textures, offsets, tiling, and other properties as needed.
4. Register the new theme in `ThemeDatabase` under `visual_background_themes`.

### Adding Layers or Elements

- Add new `BackgroundLayerConfig` entries to a theme for more parallax layers.
- Add new `BackgroundLayerElement` entries to a layer for more visual elements.

---

## Extension Points

- **Atmospherics/Transitions:** Extend `BackgroundLayerConfig` and `EnvironmentThemeConfig` with new properties.
- **Cinematic Props:** Add new element types or logic in `ParallaxLayerController`.
- **Performance:** Adjust monitoring thresholds in `ParallaxLayerController`.

---

## Consistency Guidelines

- Keep scripts under 100-150 lines; decompose if needed.
- Each class/module has a single responsibility.
- No speculative TODOs; document only current behavior.
- Use clear, explicit logic and naming.

---

## File Locations

- System scripts: `visual_background/`
- Resource scripts: `scripts/resources/`
- Theme resources: `resources/environment/themes/`
- Integration: `environment/EnvironmentSystem.tscn`, `resources/environment/ThemeDatabase.gd`

---

This documentation is up-to-date and reflects the current system architecture and usage. For further details, see the code and resource files referenced above.
