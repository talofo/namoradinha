# Camera Debug Tools

This folder contains debug tools for the camera system.

## Components

### CameraDebugTools

A debug component that allows you to toggle the camera system on/off for debugging purposes.

#### Usage

1. Add the `CameraDebugTools.tscn` scene as a child of your `CameraSystem` node
2. Use the `C` key to toggle the camera system on/off
3. Check the console for debug messages

#### Features

- Toggle camera system on/off with `C` key
- Debug messages in console
- Easy to add/remove for debugging sessions

#### Example

```gdscript
# Add to CameraSystem node
var debug_tools = load("res://camera/debug/CameraDebugTools.tscn").instantiate()
add_child(debug_tools)
```

## Debug Keys

- `C`: Toggle camera system on/off 