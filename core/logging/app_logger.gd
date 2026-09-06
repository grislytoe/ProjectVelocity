class_name ProjectLogger
extends Node
## Local console/file logging via Godot's rotating file logger. Never uploads logs.

const DEFAULT_CONFIG: AppConfig = preload("res://core/config/default_app_config.tres")


func debug(message: String, category: String = "app") -> void:
	if BuildInfo.is_development() and DEFAULT_CONFIG.log_debug_messages:
		print(format_entry("DEBUG", category, message))


func info(message: String, category: String = "app") -> void:
	print(format_entry("INFO", category, message))


func warn(message: String, category: String = "app") -> void:
	push_warning(format_entry("WARN", category, message))


func error(message: String, category: String = "app") -> void:
	push_error(format_entry("ERROR", category, message))


func format_entry(level: String, category: String, message: String) -> String:
	return "[%s][%s] %s" % [level, category, message.replace("\n", " ").replace("\r", " ")]
