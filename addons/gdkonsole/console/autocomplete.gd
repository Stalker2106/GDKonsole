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
    if autocomplete_idx != -1:
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
        active_style.bg_color = GDKonsole.colors.hover;
        new_entry.add_theme_stylebox_override("normal", active_style);
        var text = new_entry.get_meta("identifier");
        if new_entry.get_meta("argc") > 0:
            text += " ";
        get_parent().overwrite_text(text, false);

func update(text: String):
    var predicate = text.strip_edges();
    predicate = predicate.substr(0, predicate.find(" "));
    if predicate.length() < 1:
        visible = false;
        return; # Skip no text
    temp = text;
    clear_entries();
    var all_commands = get_node("/root/GDKonsole").commands;
    var all_cvars = get_node("/root/GDKonsole").cvars;
    var candidates = [];
    for command in all_commands.keys():
        if command.begins_with(predicate):
            candidates.push_back({
                "identifier": command,
                "argc": all_commands[command].arguments.size(),
                "text": all_commands[command].get_usage_string(),
                "kind": GDKonsoleCommand
            });
    for cvar in all_cvars.keys():
        if cvar.begins_with(predicate):
            candidates.push_back({
                "identifier": cvar,
                "argc": 1,
                "text": all_cvars[cvar].get_string(),
                "kind": GDKonsoleCvar
            });
    if candidates.size() > 0:
        candidates.sort_custom(func(a, b): return a["identifier"] < b["identifier"]);
        for entry_data in candidates:
            add_entry(entry_data);
        visible = true;
    else:
        visible = false;

func add_entry(entry_data: Dictionary):
    var entry = RichTextLabel.new();
    entry.fit_content = true;
    entry.autowrap_mode = TextServer.AUTOWRAP_OFF;
    entry.append_text(entry_data.text);
    entry.set_meta("identifier", entry_data.identifier);
    entry.set_meta("argc", entry_data.argc);
    entry.set_meta("kind", entry_data.kind);
    layout.add_child(entry);
    
func clear_entries():
    autocomplete_idx = -1;
    for child in layout.get_children():
        child.queue_free();

func get_entry(idx: int) -> RichTextLabel:
    return layout.get_child(idx);
