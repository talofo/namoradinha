# Camera Debug Tools

This folder contains debug tools for the camera system.

## Components

### CameraDebugTools

A debug component that allows you to freeze/unfreeze camera movement for debugging purposes.

#### Usage

1. Add the `CameraDebugTools.tscn` scene as a child of your `CameraSystem` node
2. Use the `C` key to toggle camera movement:
   - When disabled: Camera position is frozen at its current position
   - When enabled: Camera resumes normal following behavior
3. Check the console for debug messages

#### Features

- Freeze/unfreeze camera movement with `C` key
- Preserves camera position when frozen
- Debug messages in console
- Easy to add/remove for debugging sessions

#### Example

```gdscript
# Add to CameraSystem node
var debug_tools = load("res://camera/debug/CameraDebugTools.tscn").instantiate()
add_child(debug_tools)
```

## Debug Keys

- `C`: Toggle camera movement (freeze/unfreeze) 