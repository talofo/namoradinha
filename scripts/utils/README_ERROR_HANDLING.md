# Error Handling System

This document describes the standardized error handling system implemented in the game to improve code maintainability, debugging, and error reporting.

## Overview

The error handling system provides a centralized way to log messages, warnings, and errors with consistent formatting and context. It helps with:

- Standardizing error message format
- Providing context about the source of errors
- Controlling debug output
- Making error handling more consistent across the codebase

## Implementation

The system is implemented in `ErrorHandler.gd`, which is registered as an autoload singleton in the project settings. This makes it available throughout the project as a global object named `ErrorHandler`.

### Error Levels

The system supports four levels of messages:

1. **INFO**: General information messages
2. **WARNING**: Non-critical issues that should be addressed
3. **ERROR**: Critical issues that prevent normal operation
4. **DEBUG**: Detailed information for debugging (only shown when debug mode is enabled)

### Usage

#### Basic Usage

Since ErrorHandler is registered as an autoload singleton, you can use it directly in any script without needing to import or preload it:

```gdscript
# Log an informational message
ErrorHandler.info("ClassName", "Something happened")

# Log a warning
ErrorHandler.warning("ClassName", "Something unexpected happened")

# Log an error
ErrorHandler.error("ClassName", "Something went wrong")

# Log a debug message (only shown if debug is enabled)
ErrorHandler.debug("ClassName", "Detailed debug information")
```

#### Specialized Error Functions

The system also provides specialized functions for common error scenarios:

```gdscript
# Log a null check failure
ErrorHandler.null_check_failed("ClassName", "variable_name", "Make sure to initialize it before use")

# Log a method not found error
ErrorHandler.method_not_found("ClassName", "object_name", "method_name")

# Log a resource not found error
ErrorHandler.resource_not_found("ClassName", "res://path/to/resource.tres")

# Log a configuration error
ErrorHandler.configuration_error("ClassName", "config_name", "Invalid value")
```

#### Debug Mode

Debug messages are only shown when debug mode is enabled:

```gdscript
# Enable debug messages
ErrorHandler.set_debug_enabled(true)

# Disable debug messages
ErrorHandler.set_debug_enabled(false)
```

## Benefits

1. **Consistency**: All error messages follow the same format
2. **Context**: Error messages include the source class/component
3. **Filtering**: Different levels of messages can be filtered
4. **Extensibility**: New error types can be added easily

## Best Practices

1. **Always Include Source**: The first parameter should be the class or component name
2. **Be Specific**: Error messages should be clear and specific
3. **Suggest Solutions**: Where possible, include suggestions for fixing the issue
4. **Use Appropriate Level**: Use the appropriate error level for the situation
5. **Format Messages**: Use string formatting for complex messages

## Example

Before:
```gdscript
if not motion_system:
    push_error("MotionSystem node not found!")
    return
```

After:
```gdscript
if not motion_system:
    ErrorHandler.error("Game", "MotionSystem node not found!")
    return
```

## Recent Implementations

The error handling system has been implemented in the following areas:

### Motion System

The Motion System has been updated to use ErrorHandler for all logging and error reporting:

1. **LaunchSystem**: Replaced all print(), push_warning(), and push_error() calls with appropriate ErrorHandler methods
2. **BounceSystem**: Replaced all print(), push_warning(), and push_error() calls with appropriate ErrorHandler methods
3. **Other Subsystems**: Will be updated in future iterations

This standardization improves the consistency of error messages and makes debugging easier by providing better context about the source of errors.

Example of the updated pattern in subsystems:

```gdscript
# Before
if not _motion_system or not _motion_system.has_method("get_physics_config"):
    push_error("[SubsystemName] MotionSystem or get_physics_config method not available.")
    return fallback_value

# After
if not _motion_system or not _motion_system.has_method("get_physics_config"):
    ErrorHandler.error("SubsystemName", "MotionSystem or get_physics_config method not available.")
    return fallback_value
```

## Future Improvements

1. **Log to File**: Add option to log messages to a file
2. **Error Categories**: Add categories for different types of errors
3. **Error Codes**: Add error codes for easier reference
4. **Stack Traces**: Include stack traces for errors
5. **Error Aggregation**: Group similar errors to avoid spam
