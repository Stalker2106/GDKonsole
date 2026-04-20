extends RefCounted

# Behaviour
const console_height: String = "40%";
const max_lines: int = 500;
const toggle_speed: float = 2.0;

# Features
const allow_inputmap_edition: bool = false;
const allow_tree_edition: bool = true;

const enable_gdlogger_intercept: bool = false;
var enable_log_to_file: bool = false;
const logfile_path: String = "user://gdkonsole.log";
