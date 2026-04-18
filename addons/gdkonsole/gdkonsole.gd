extends Node

signal toggled;

var GUIScene = preload("./GUI.tscn");

var colors;
var builtins;

var gui;
var animator;
var input : LineEdit;
var content : RichTextLabel;

var commands : Dictionary;

var visible : bool;

func _init() -> void:
    commands = {};
    visible = false;
    colors = load("res://addons/gdkonsole/colors.gd");
    # Builtins
    builtins = load("res://addons/gdkonsole/builtins.gd");
    add_command("echo", builtins, "print").add_argument("text", TYPE_STRING).set_description("Prints text to console");
    add_command("help", builtins, "print_help").set_description("Shows all existing commands");
    add_command("exec", builtins, "exec").add_argument("path", TYPE_STRING).set_description("Execute a commands file line by line from given path");
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
    input = gui.get_node("Console/Layout/Input");
    input.connect("text_submitted", Callable(self, "eval_input"));
    input.connect("text_changed", Callable(self, "reset_history_idx"));
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
            input.grab_focus();
        else:
            input.release_focus();
            animator.play_backwards("Dropdown");
            await animator.animation_finished;
            gui.visible = false;

func add_command(name: String, target_obj : Object, target_method : String) -> GDKonsoleCommand:
    if !name.is_valid_unicode_identifier():
        write_error("Error: unable to register command `%s`. Invalid identifier" % name);
        return;
    if commands.has(name):
        write_error("Error: unable to register command `%s`. Overrides existing command" % name);
        return;
    var cmd = GDKonsoleCommand.new(name, target_obj, target_method);
    commands[name] = cmd;
    return cmd;

func eval_input(input_fullcmd: String):
    write_line("[color=gray]>[/color]%s" % input_fullcmd);
    if eval(input_fullcmd, true):
        content.scroll_to_bottom();
    # Clear input
    input.clear();

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

func eval(fullcmd: String, historize: bool = false) -> bool:
    var argv: Array = parse_argv(fullcmd);
    if argv.is_empty():
        return false; # Nothing to eval
    var actual_cmd = argv.pop_front();
    if actual_cmd == null || actual_cmd.is_empty():
        return false; #Nothing to eval
    # Add to history if needed
    if historize:
        input.historize(fullcmd);
    # execute
    if !commands.has(actual_cmd):
        write_error("Command `[color=%s]%s[/color]` not found. type '[color=%s]help[/color]' to view all commands" % [GDKonsole.colors.command.to_html(false), actual_cmd, GDKonsole.colors.command.to_html(false)]);
        return true;
    commands[actual_cmd].execute(argv);
    return true;

# Content passthrough
func write(err: String = "", color: Color = colors.default):
    content.write_line(err, color);

func write_line(err: String = "", color: Color = colors.default):
    content.write_line(err, color);
    
func write_error(err: String = ""):
    content.write_line(err, colors.error);
