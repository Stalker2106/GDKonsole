extends RefCounted
class_name GDKonsoleCvar

var name : String;
var description : String;
var target_obj : Object;
var target_property : String;

func _init(name_: String, target_obj_: Object, target_property_: String):
    name = name_;
    target_obj = target_obj_;
    target_property = target_property_;

func set_description(desc: String):
    description = desc;

func get_value() -> Variant:
    return target_obj.get(target_property);

func set_value(argv: Array) -> void:
    var argc = argv.size();
    if argc != 1:
        var err;
        if argc > 1:
            err = "Too many arguments";
        elif argc < 1:
            err = "Missing value";
        GDKonsole.write_error("Error: %s: setting cvar expects 1 argument, %d provided." % [err, argc]);
        return;
    # Set
    if argv[0] is String:
        var type_hint = typeof(target_obj.get(target_property));
        target_obj.set(target_property, GDKonsole.str_to_variant(argv[0], type_hint));
    else:
        target_obj.set(target_property, argv[0]);

func get_string() -> String:
    return "[color=%s]%s[/color] %s" % [GDKonsole.colors.cvar.to_html(false), name, str(get_value())];
