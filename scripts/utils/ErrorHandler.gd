extends Node

# Error levels for different types of messages
enum Level {INFO, WARNING, ERROR, DEBUG}

# Whether debug messages should be shown
var show_debug_messages: bool = false

# Log a message with the specified error level
# source: The class or component that generated the message
# message: The message to log
# level: The error level (from the Level enum)
func log_message(source: String, message: String, level: Level = Level.INFO) -> void:
	var formatted_message = _format_message(source, message)
	
	match level:
		Level.INFO:
			print(formatted_message)
		Level.WARNING:
			push_warning(formatted_message)
		Level.ERROR:
			push_error(formatted_message)
		Level.DEBUG:
			if show_debug_messages:
				print("[DEBUG] " + formatted_message)

# Log an informational message
# source: The class or component that generated the message
# message: The message to log
func info(source: String, message: String) -> void:
	log_message(source, message, Level.INFO)

# Log a warning message
# source: The class or component that generated the message
# message: The message to log
func warning(source: String, message: String) -> void:
	log_message(source, message, Level.WARNING)

# Log an error message
# source: The class or component that generated the message
# message: The message to log
func error(source: String, message: String) -> void:
	log_message(source, message, Level.ERROR)

# Log a debug message (only shown if show_debug_messages is true)
# source: The class or component that generated the message
# message: The message to log
func debug(source: String, message: String) -> void:
	log_message(source, message, Level.DEBUG)

# Enable or disable debug messages
# enabled: Whether debug messages should be shown
func set_debug_enabled(enabled: bool) -> void:
	show_debug_messages = enabled

# Format a message with the source
# source: The class or component that generated the message
# message: The message to log
# Returns: The formatted message
func _format_message(source: String, message: String) -> String:
	return "[%s] %s" % [source, message]

# Log a method entry (useful for tracing)
# source: The class that contains the method
# method_name: The name of the method
func trace_method_entry(source: String, method_name: String) -> void:
	if show_debug_messages:
		debug(source, "Entering method: %s" % method_name)

# Log a method exit (useful for tracing)
# source: The class that contains the method
# method_name: The name of the method
func trace_method_exit(source: String, method_name: String) -> void:
	if show_debug_messages:
		debug(source, "Exiting method: %s" % method_name)

# Log a null check failure
# source: The class that contains the check
# variable_name: The name of the variable that was null
# suggestion: A suggestion for how to fix the issue
func null_check_failed(source: String, variable_name: String, suggestion: String = "") -> void:
	var message = "%s is null" % variable_name
	if suggestion:
		message += ". %s" % suggestion
	error(source, message)

# Log a method not found error
# source: The class that tried to call the method
# object_name: The name of the object that should have the method
# method_name: The name of the method that was not found
func method_not_found(source: String, object_name: String, method_name: String) -> void:
	error(source, "Method '%s' not found on %s" % [method_name, object_name])

# Log a resource not found error
# source: The class that tried to load the resource
# resource_path: The path of the resource that was not found
func resource_not_found(source: String, resource_path: String) -> void:
	error(source, "Resource not found at path: %s" % resource_path)

# Log a configuration error
# source: The class that encountered the configuration error
# config_name: The name of the configuration that had an error
# message: A description of the error
func configuration_error(source: String, config_name: String, message: String) -> void:
	error(source, "Configuration error in %s: %s" % [config_name, message])
