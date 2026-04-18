extends PanelContainer

var layout;

var autocomplete_idx : int;
var temp : String;

func _init() -> void:
    autocomplete_idx = -1;
    
func _ready() -> void:
    layout = get_node("Layout");

func _input(event: InputEvent) -> void:
    if visible:
        if event is InputEventKey && event.is_pressed():
            if event.keycode == KEY_TAB:
                move_autocomplete_idx(1);
                get_viewport().set_input_as_handled();

func move_autocomplete_idx(amount: int):
    # Remove old style if any
    var old_entry = get_entry(autocomplete_idx);
    if old_entry:
        old_entry.add_theme_stylebox_override("normal", StyleBoxEmpty.new());
    # Move autocomplete cursor
    autocomplete_idx += amount;
    if autocomplete_idx >= layout.get_child_count():
        autocomplete_idx = -1;
    # Reset back to input
    if autocomplete_idx == -1:
        get_parent().overwrite_text(temp, false);
        return;
    # Handle autocomplete
    var new_entry = get_entry(autocomplete_idx);
    if new_entry:
        var active_style = StyleBoxFlat.new();
        active_style.bg_color = Color.WEB_GRAY;
        new_entry.add_theme_stylebox_override("normal", active_style);
        get_parent().overwrite_text(new_entry.get_text(), false);

func update(predicate: String):
    if predicate.length() < 1:
        visible = false;
        return; # Skip no text
    temp = predicate;
    clear_entries();
    var all_commands = get_node("/root/GDKonsole").commands;
    var candidates = [];
    for command in all_commands.keys():
        if command.begins_with(predicate):
            candidates.push_back(command);
    if candidates.size() > 0:
        candidates.sort();
        for command in candidates:
            add_entry(command);
        visible = true;
    else:
        visible = false;

func add_entry(command: String):
    var entry = Label.new();
    entry.set_text(command);
    layout.add_child(entry);
    
func clear_entries():
    autocomplete_idx = -1;
    for child in layout.get_children():
        child.queue_free();

func get_entry(idx: int) -> Label:
    return layout.get_child(idx);
