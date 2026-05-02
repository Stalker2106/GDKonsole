extends RefCounted

# Behaviour
var console_height: String = "40%";
var max_lines: int = 500;
var toggle_speed: float = 2.0;

# Features
var allow_inputmap_edition: bool = false;
var allow_tree_edition: bool = true;

var enable_gderror_intercept: bool = false;
var enable_gdmessage_intercept: bool = false;
var enable_log_to_file: bool = false;
var logfile_path: String = "user://gdkonsole.log";
