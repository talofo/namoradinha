# Visual Background Debug Tools

This folder contains debug tools for the visual background system.

## Components

### BackgroundDebugTools

A debug component that allows you to toggle the visual background system on/off for debugging purposes.

#### Usage

1. Add the `BackgroundDebugTools.tscn` scene as a child of your `VisualBackgroundSystem` node
2. Use the `B` key to toggle the background system on/off
3. Check the console for debug messages

#### Features

- Toggle background system on/off with `B` key
- Debug messages in console
- Easy to add/remove for debugging sessions

#### Example

```gdscript
# Add to VisualBackgroundSystem node
var debug_tools = load("res://visual_background/debug/BackgroundDebugTools.tscn").instantiate()
add_child(debug_tools)
```

## Debug Keys

- `B`: Toggle background system on/off 