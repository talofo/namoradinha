# Movement Debug Tools

This folder contains debug tools for analyzing player movement and system interactions.

## Components

### MovementDebugTools

A comprehensive debug component that allows you to toggle both camera and background systems simultaneously for movement analysis.

#### Usage

1. Add the `MovementDebugTools.tscn` scene to any node in your game scene
2. Use the following keys to toggle systems:
   - `B`: Toggle background system on/off
   - `C`: Toggle camera system on/off
3. Watch the status display in the top-left corner for current system states

#### Features

- Toggle both camera and background systems from one place
- Visual status display showing current system states
- Debug messages in console
- Easy to add/remove for debugging sessions

#### Example

```gdscript
# Add to any node in your game scene
var debug_tools = load("res://scripts/player/debug/MovementDebugTools.tscn").instantiate()
add_child(debug_tools)
```

## Debug Keys

- `B`: Toggle background system on/off
- `C`: Toggle camera system on/off

## Status Display

The status display shows:
- Current state of the background system
- Current state of the camera system
- Key bindings for toggling systems 