extends Node

signal toggled;

var GUIScene = preload("../GUI.tscn");

var constants;
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
    # Load colors & constants
    constants = load("res://addons/gdkonsole/style/constants.gd").new();
    colors = load("res://addons/gdkonsole/style/colors.gd").new();

func _ready() -> void:
    gui = GUIScene.instantiate();
    animator = gui.get_node("AnimationPlayer");
    add_child(gui);
    gui.visible = false;
    get_tree().root.connect("size_changed", Callable(self, "reload_constants"));
    # Bind locals
    content = gui.get_node("Console/Layout/ScrollContainer/Content");
    kinput = gui.get_node("Console/Layout/Input");
    kinput.connect("text_submitted", Callable(self, "eval_input"));
    # Intercept godot msg/errors
    if constants.enable_gdlogger_intercept:
        OS.add_logger(load("res://addons/gdkonsole/console/gdintercept.gd").new());
    # Register Builtins
    builtins = load("res://addons/gdkonsole/console/builtins.gd").new();
    add_command("echo", builtins, "print").add_argument("text", TYPE_STRING).set_description("Prints text to console");
    add_command("help", builtins, "print_help").set_description("Shows all existing commands");
    add_command("exec", builtins, "exec").add_argument("path", TYPE_STRING).set_description("Executes a file containing commands from given path (line by line)");
    # Complimentary builtins
    if constants.allow_inputmap_edition:
        add_command("bind", builtins, "bind").add_argument("key", TYPE_STRING) \
            .add_argument("action", TYPE_STRING).set_description("Binds a key to an action");
        add_command("unbind", builtins, "bind").add_argument("key", TYPE_STRING) \
            .add_argument("action", TYPE_STRING).set_description("Unbinds a key from an action");
    if constants.allow_tree_edition:
        add_command("inspect", builtins, "inspect_node").add_argument("node_path", TYPE_STRING) \
            .set_description("Inspects node at node_path");
    # Apply styles & constants
    reload_styles();
    reload_constants();

func reload_styles():
    # Theme
    var theme = gui.get_node("Console").theme;
    theme.set_color("panel", "PanelContainer", GDKonsole.colors.background);
    var inputstyle = theme.get_stylebox("normal", "LineEdit");
    inputstyle.border_color = GDKonsole.colors.border;
    theme.set_color("default_color", "RichTextLabel", GDKonsole.colors.default);
    theme.set_color("selection_color", "RichTextLabel", GDKonsole.colors.hover);
    var scrollstyle = theme.get_stylebox("grabber", "VScrollBar");
    scrollstyle.bg_color = GDKonsole.colors.border;
    scrollstyle = theme.get_stylebox("grabber_highlight", "VScrollBar");
    scrollstyle.bg_color = GDKonsole.colors.hover;
    scrollstyle = theme.get_stylebox("grabber_pressed", "VScrollBar");
    scrollstyle.bg_color = GDKonsole.colors.border;

func reload_constants():
    var console = gui.get_node("Console");
    # Size
    var vp_size = get_viewport().get_visible_rect().size;
    var size_factor = float(GDKonsole.constants.console_height.replace("%", "")) / 100;
    console.size = Vector2(vp_size.x, vp_size.y * size_factor);
    console.position = Vector2(0, -console.size.y if !gui.visible else 0);
    # Anims
    var animator = gui.get_node("AnimationPlayer");
    var drop_anim = animator.get_animation("Dropdown");
    var pos_track = drop_anim.find_track("Console:position", Animation.TrackType.TYPE_VALUE);
    drop_anim.track_set_key_value(pos_track, 0, Vector2(0, -console.size.y));
    # Scroll to bottom because size changed and may leave weird content pos
    content.scroll_to_bottom();
    
func override_theme(new_theme: Theme):
    var console = gui.get_node("Console");
    console.set_theme(new_theme);

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("gdkonsole_toggle"):
        get_viewport().set_input_as_handled();
        emit_signal("toggled", visible);
        if !gui.visible:
            gui.visible = true;
            animator.play("Dropdown", -1, constants.toggle_speed);
            kinput.grab_focus();
        else:
            kinput.release_focus();
            animator.play("Dropdown", -1, -constants.toggle_speed, true);
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

func write_texture(tex_path: String):
    content.write_texture(tex_path);

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
