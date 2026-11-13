extends Node

static func print(msg: String):
    GDKonsole.write_line(msg);

static func print_all_commands():
    var all_commands = GDKonsole.commands;
    GDKonsole.write_line("List of available commands:");
    for cmd_name in all_commands.keys():
        GDKonsole.write_line(all_commands[cmd_name].get_desc_string());

static func print_all_cvars():
    var all_cvars = GDKonsole.cvars;
    GDKonsole.write_line("List of registered CVars:");
    for var_name in all_cvars.keys():
        GDKonsole.write_line(all_cvars[var_name].get_desc_string());

static func exec(path: String):
    var script = FileAccess.open(path, FileAccess.READ);
    if script == null:
        GDKonsole.write_error("Error: failed to open `%s`" % path);
        return;
    while !script.eof_reached():
        var line = script.get_line();
        GDKonsole.eval(line);

# Evaluates a single GDScript expression (`1 + 2`, `get_tree().root.name`, `Engine.time_scale`...)
# and prints its result.
static func eval(gdscript: String):
    var code = gdscript.strip_edges();
    if code.is_empty():
        return;
    var inputs = get_expression_inputs();
    var expression = Expression.new();
    if expression.parse(code, inputs.keys()) != OK:
        GDKonsole.write_error("Error: failed to parse expression: %s" % expression.get_error_text());
        return;
    var result = expression.execute(inputs.values(), GDKonsole);
    if expression.has_execute_failed():
        GDKonsole.write_error("Error: failed to execute expression: %s" % expression.get_error_text());
        return;
    GDKonsole.write_line(str(result));

# Expression only knows its base instance and explicit inputs: expose engine
# singletons (Engine, Input, OS...) and autoloads so they're usable like in GDScript.
static func get_expression_inputs() -> Dictionary:
    var inputs = {};
    for singleton_name in Engine.get_singleton_list():
        inputs[singleton_name] = Engine.get_singleton(singleton_name);
    var root = (Engine.get_main_loop() as SceneTree).root;
    for property in ProjectSettings.get_property_list():
        var setting : String = property.name;
        if setting.begins_with("autoload/"):
            var autoload = root.get_node_or_null(setting.trim_prefix("autoload/"));
            if autoload:
                inputs[autoload.name] = autoload;
    return inputs;

# InputMap

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

# Nodes
static func inspect_node(node_path: String) -> void:
    var args = node_path.split(":")
    var tree = Engine.get_main_loop() as SceneTree
    var node = tree.current_scene.get_node_or_null(args[0])
    if not node:
        GDKonsole.write_error("Error: path `%s` does not exist" % args[0])
        return

    GDKonsole.write_line("[INSPECT %s (%s)]" % [node_path, node.get_class()], Color.ORANGE)
    inspect_value(node, args.slice(1), 0)


static func inspect_value(obj: Object, chain: Array, depth: int) -> void:
    # No keys left — enumerate the object's properties
    if chain.is_empty() or depth >= chain.size():
        for prop in obj.get_property_list():
            if prop["usage"] & PROPERTY_USAGE_EDITOR:
                GDKonsole.write_line(" %s = %s" % [prop["name"], obj.get(prop["name"])])
        return;
    var key = chain[depth]
    var value = obj.get(key)
    if value == null:
        GDKonsole.write_error("Error: property `%s` does not exist on `%s`" % [key, obj.get_class()])
        return;
    if depth < chain.size() - 1:
        if value is Object:
            inspect_value(value, chain, depth + 1)
        else:
            GDKonsole.write_error("Error: `%s` is not an Object, cannot access `%s` on it" % [key, chain[depth + 1]])
        return;
    # Final value
    if value is Texture2D:
        GDKonsole.write_texture(value.resource_path)
    elif value is Color:
        var hex = value.to_html(false)
        GDKonsole.write_line("[bgcolor=#%s]#%s[/bgcolor]" % [hex, hex])
    elif value is Object:
        inspect_value(value, [], 0);
    else:
        GDKonsole.write_line("%s = %s" % [":".join(chain), value])
