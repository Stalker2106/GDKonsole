extends Node

signal toggled;

var GUIScene = preload("./GUI.tscn");

var colors;
var builtins;

var gui;
var animator;
var kinput : LineEdit;
var content : RichTextLabel;

var commands : Dictionary;
var cvars : Dictionary;

var visible : bool;

func _init() -> void:
    commands = {};
    cvars = {};
    visible = false;
    colors = load("res://addons/gdkonsole/colors.gd");
    # Builtins
    builtins = load("res://addons/gdkonsole/builtins.gd");
    add_command("echo", builtins, "print").add_argument("text", TYPE_STRING).set_description("Prints text to console");
    add_command("help", builtins, "print_help").set_description("Shows all existing commands");
    add_command("exec", builtins, "exec").add_argument("path", TYPE_STRING).set_description("Executes a file containing commands from given path (line by line)");
    # These builtins are complimentary, uncomment if needed!
    #add_command("bind", builtins, "bind").add_argument("key", TYPE_STRING) \
    #    .add_argument("action", TYPE_STRING).set_description("Binds a key to an action");
    #add_command("unbind", builtins, "bind").add_argument("key", TYPE_STRING) \
    #    .add_argument("action", TYPE_STRING).set_description("Unbinds a key from an action");

func _ready() -> void:
    gui = GUIScene.instantiate();
    animator = gui.get_node("AnimationPlayer");
    add_child(gui);
    gui.visible = false;
    # Bind locals
    content = gui.get_node("Console/Layout/ScrollContainer/Content");
    kinput = gui.get_node("Console/Layout/Input");
    kinput.connect("text_submitted", Callable(self, "eval_input"));
    # Intercept godot msg/errors
    OS.add_logger(load("res://addons/gdkonsole/gdintercept.gd").new());

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("gdkonsole_toggle"):
        get_viewport().set_input_as_handled();
        visible = !visible;
        emit_signal("toggled", visible);
        if visible:
            gui.visible = true;
            animator.play("Dropdown");
            kinput.grab_focus();
        else:
            kinput.release_focus();
            animator.play_backwards("Dropdown");
            await animator.animation_finished;
            gui.visible = false;

func register_guard(identifier: String) -> bool:
    if !identifier.is_valid_unicode_identifier():
        write_error("Error: unable to register `%s`. Invalid identifier" % identifier);
        return false;
    if commands.has(identifier) || cvars.has(identifier):
        write_error("Error: unable to register `%s`. Overrides existing command/cvar" % name);
        return false;
    return true;

func add_cvar(name: String, target_obj: Object, target_property: String) -> GDKonsoleCvar:
    if !register_guard(name):
        return;
    var cvar = GDKonsoleCvar.new(name, target_obj, target_property);
    cvars[name] = cvar;
    return cvar;

func add_command(name: String, target_obj: Object, target_method: String) -> GDKonsoleCommand:
    if !register_guard(name):
        return;
    var cmd = GDKonsoleCommand.new(name, target_obj, target_method);
    commands[name] = cmd;
    return cmd;

func eval_input(input_fullcmd: String):
    if input_fullcmd.strip_edges().is_empty():
        return; # Nothing to eval
    write_line("[color=gray]>[/color]%s" % input_fullcmd);
    if eval(input_fullcmd, true):
        content.scroll_to_bottom();
    # Clear input
    kinput.clear();

func parse_argv(fullcmd: String) -> Array:
    var argv: Array = []
    var current: String = ""
    var in_single: bool = false
    var in_double: bool = false
    var escaped: bool = false
    var i: int = 0
    var buffer: String = fullcmd.strip_edges();
    while i < buffer.length():
        var ch: String = buffer[i];
        if escaped:
            current += ch;
            escaped = false;
        elif ch == '\\':
            escaped = true;
        elif ch == "'" and not in_double:
            in_single = !in_single;
        elif ch == '"' and not in_single:
            in_double = !in_double;
        elif ch == ' ' and not in_single and not in_double:
            if not current.is_empty():
                argv.append(current);
                current = "";
        else:
            current += ch;
        i += 1
    if not current.is_empty():
        argv.append(current);
    return argv;

func eval(buffer: String, historize: bool = false) -> bool:
    var argv: Array = parse_argv(buffer);
    if argv.is_empty():
        return false; # Nothing to eval
    var identifier = argv.pop_front();
    if identifier == null || identifier.is_empty():
        return false; #Nothing to eval
    # Add to history if needed
    if historize:
        kinput.historize(buffer);
    # handle cvar or execute
    if cvars.has(identifier):
        cvars[identifier].set_value(argv);
        return true;
    elif commands.has(identifier):
        commands[identifier].execute(argv);
        return true;
    write_error("Identifier `[color=%s]%s[/color]` not found. type '[color=%s]help[/color]' to view all commands" % [GDKonsole.colors.command.to_html(false), identifier, GDKonsole.colors.command.to_html(false)]);
    return false;

# Content passthrough
func write(err: String = "", color: Color = colors.default):
    content.write_line(err, color);

func write_line(err: String = "", color: Color = colors.default):
    content.write_line(err, color);
    
func write_error(err: String = ""):
    content.write_line(err, colors.error);

# Util

static func str_to_variant(str: String, expected_type: Variant.Type) -> Variant:
    match expected_type:
        TYPE_INT:
            if str.is_valid_int() || str.is_valid_float():
                return int(str);
            else:
                GDKonsole.write_error("Error: %s is not a valid int." % str);
                return;
        TYPE_FLOAT:
            if str.is_valid_int() || str.is_valid_float():
                return float(str);
            else:
                GDKonsole.write_error("Error: %s is not a valid float." % str);
                return;
        TYPE_BOOL:
            if str == "true" || (str.is_valid_int() && int(str) != 0):
                return true;
            elif str == "false" || (str.is_valid_int() && int(str) == 0):
                return false;
            else:
                GDKonsole.write_error("Error: %s is not a valid bool" % str);
                return;
        TYPE_STRING:
            return str;
        _:
            return str_to_var(str);
    return null;
