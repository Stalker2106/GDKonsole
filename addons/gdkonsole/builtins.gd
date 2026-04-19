extends Node

static func print(msg: String):
    GDKonsole.write_line(msg);

static func print_help():
    var all_commands = GDKonsole.commands;
    GDKonsole.write_line("List of available commands:");
    for cmd_name in all_commands.keys():
        GDKonsole.write_line(all_commands[cmd_name].get_desc_string());

static func exec(path: String):
    var script = FileAccess.open(path, FileAccess.READ);
    if script == null:
        GDKonsole.write_error("Error: failed to open `%s`" % path);
        return;
    while !script.eof_reached():
        var line = script.get_line();
        GDKonsole.eval(line);

static func bind(key: String, action: String):
    var keycode = OS.find_keycode_from_string(key)
    if keycode == KEY_NONE:
        GDKonsole.write_error("Error: `%s` is not a valid keycode" % key);
        return;
    # Check that action exists
    if not InputMap.has_action(action):
        GDKonsole.write_error("Error: no action `%s` exists" % action);
        return;
    # Add key as event
    var event = InputEventKey.new();
    event.keycode = keycode;
    InputMap.action_add_event(action, event);

static func unbind(key: String, action: String):
    var keycode = OS.find_keycode_from_string(key)
    if keycode == KEY_NONE:
        GDKonsole.write_error("Error: `%s` is not a valid keycode" % key);
        return;
    # Check that action exists
    if not InputMap.has_action(action):
        GDKonsole.write_error("Error: no action `%s` exists" % action);
        return;
    # Erase all matching events
    for event in InputMap.action_get_events(action):
        if event is InputEventKey && event.keycode == keycode:
            InputMap.action_erase_event(action, event);
