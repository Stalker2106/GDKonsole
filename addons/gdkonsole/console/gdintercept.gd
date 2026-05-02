extends Logger

func _log_message(message: String, error: bool) -> void:
    if !GDKonsole.config.enable_gdmessage_intercept:
        return; #Logging messages are disabled
    if error:
        GDKonsole.write_error(message);
    else:
        GDKonsole.write_line(message);

func _log_error(
    function: String,
    file: String,
    line: int,
    code: String,
    rationale: String,
    editor_notify: bool,
    error_type: int,
    script_backtraces: Array[ScriptBacktrace]
) -> void:
    if !GDKonsole.config.enable_gderror_intercept:
        return; #Logging errors are disabled
    var location = "%s:%d (%s)" % [file, line, function]
    var msg = "[%s] %s — %s" % [code, rationale, location]
    
    # optionally print backtraces
    for bt in script_backtraces:
        msg += "\n  " + bt.to_string()  # check actual ScriptBacktrace API
    
    GDKonsole.write_error(msg);
