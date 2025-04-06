# Motion System Signal Connections

## Overview

This document describes the signal connections between subsystems in the Motion System. Signals are used to communicate between subsystems without creating direct dependencies, promoting loose coupling and making the system more maintainable.

## Signal Architecture

The Motion System uses a signal-based architecture for inter-subsystem communication. Each subsystem can:

1. **Provide Signals**: Define and emit signals that other subsystems can connect to
2. **Depend on Signals**: Connect to signals provided by other subsystems

This approach allows subsystems to interact without direct references to each other, making the system more modular and easier to extend.

## Signal Registration

Signals are registered and connected during the subsystem registration process in MotionSystemCore. Each subsystem implements two methods to declare its signal relationships:

```gdscript
# Returns a dictionary of signals this subsystem provides
# The dictionary keys are signal names, values are signal parameter types
func get_provided_signals() -> Dictionary:
    return {
        "signal_name": ["param_type1", "param_type2", ...]
    }

# Returns an array of signal dependencies this subsystem needs
# Each entry is a dictionary with provider, signal_name, and method
func get_signal_dependencies() -> Array:
    return [
        {
            "provider": "ProviderSubsystemName",
            "signal_name": "signal_name",
            "method": "method_to_connect"
        }
    ]
```

## Current Signal Connections

### LaunchSystem

**Provides:**
- `entity_launched(entity_id: int, launch_vector: Vector2, position: Vector2)`: Emitted when an entity is launched

**Dependencies:**
- None

### BounceSystem

**Provides:**
- None

**Dependencies:**
- `LaunchSystem.entity_launched` → `BounceSystem.record_launch`: Notifies the BounceSystem when an entity is launched

### Other Subsystems

Other subsystems may provide or depend on signals as needed. The signal architecture allows for easy extension of the system with new signals and connections.

## Signal Flow Example

A typical signal flow in the Motion System might look like this:

1. Player initiates a launch action
2. Game code calls `LaunchSystem.launch_entity()`
3. LaunchSystem calculates the launch vector and emits the `entity_launched` signal
4. BounceSystem receives the signal via its `record_launch` method
5. BounceSystem records the launch data for future bounce calculations

## Benefits of Signal-Based Architecture

1. **Loose Coupling**: Subsystems don't need direct references to each other
2. **Extensibility**: New subsystems can easily connect to existing signals
3. **Testability**: Subsystems can be tested in isolation by mocking signals
4. **Maintainability**: Changes to one subsystem don't require changes to others
5. **Flexibility**: Signal connections can be dynamically created and removed

## Best Practices

1. **Clear Documentation**: Document all signals and their parameters
2. **Consistent Naming**: Use consistent naming conventions for signals
3. **Minimal Parameters**: Pass only necessary data in signals
4. **Type Safety**: Specify parameter types in `get_provided_signals()`
5. **Error Handling**: Handle missing signal providers gracefully
