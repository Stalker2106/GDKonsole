extends RefCounted
class_name GDKonsoleCommand

var name : String;
var description : String;
var arguments : Array;

var callback : Callable;

func _init(name_: String, target_obj_ : Object, target_method_ : String):
    name = name_;
    callback = Callable(target_obj_, target_method_);
    arguments = [];

func set_description(description_ : String) -> GDKonsoleCommand:
    description = description_;
    return self;

func add_argument(name_: String, type_: Variant.Type, default_value: Variant = null) -> GDKonsoleCommand:
    arguments.push_back({"name": name_, "type": type_, "default": default_value});
    return self;

func get_req_arg_count():
    var count = 0;
    for arg in arguments:
        if arg.default == null:
            count += 1;
        else:
            break;
    return count;

func execute(argv : Array):
    var argc = argv.size();
    var arg_count = arguments.size();
    var req_arg_count = get_req_arg_count();
    # Handle wrong arguments count
    if argc != req_arg_count:
        if argc > arg_count:
            GDKonsole.write_error("Error: Too many arguments: command expects %d arguments, %d provided." % [req_arg_count, argc]);
        elif argc < req_arg_count:
            GDKonsole.write_error("Error: Missing arguments: command expects %d arguments, %d provided." % [req_arg_count, argc]);
        return;
    # Insert default values
    for arg_idx in range(0, arg_count - argc):
        argv.push_front(arguments[arg_idx].default);
    # Execution
    var casted_argv = [];
    for arg_idx in range(0, arg_count):
        var expected_type = arguments[arg_idx].type;
        # Handle extracting args from prompt string (default values are variant injected)
        if argv[arg_idx] is String:
            casted_argv.push_back(GDKonsole.str_to_variant(argv[arg_idx], expected_type));
        else:
            casted_argv.push_back(argv[arg_idx]);
    callback.callv(casted_argv);

func get_usage_string() -> String:
    var str = "[color=%s]%s[/color]" % [GDKonsole.colors.command.to_html(false), name];
    if arguments.size() > 0:
        for arg in arguments:
            str += " <%s:[color=%s]%s[/color]" % [arg.name, GDKonsole.colors.type.to_html(false), type_string(arg.type)];
            if arg.default != null:
                str +=  "=%s" % str(arg.default);
            str +=  ">";
    return str;

func get_desc_string() -> String:
    var str = get_usage_string();
    if description:
        str += "  [color=%s]%s[/color]" % [GDKonsole.colors.comment.to_html(false), description];
    return str;
