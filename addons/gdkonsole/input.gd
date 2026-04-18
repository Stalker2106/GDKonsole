extends LineEdit

var autocomplete;

var history : Array;
var history_idx : int;

var temp : String;

func _init() -> void:
    history = [];
    history_idx = -1;
    connect("text_changed", Callable(self, "_on_text_changed"));

func _ready() -> void:
    autocomplete = get_node("Autocomplete");

func _on_text_changed(new_text: String):
    temp = new_text;
    reset_history_idx();
    autocomplete.update(new_text);

func _input(event: InputEvent) -> void:
    if visible:
        if event is InputEventKey && event.is_pressed():
            grab_focus();
            var history_key = false;
            match event.keycode:
                KEY_UP:
                    if history_idx < history.size()-1:
                        history_key = true;
                        history_idx = history_idx + 1;
                    get_viewport().set_input_as_handled();
                KEY_DOWN:
                    if history_idx >= 0:
                        history_key = true;
                        history_idx = history_idx - 1;
                    get_viewport().set_input_as_handled();
            # Update input with history
            if history_key:
                if history_idx == -1:
                    overwrite_text(temp, true);
                else:
                    overwrite_text(history[history_idx], true);

func reset_history_idx(idx = 0):
    history_idx = -1;

func historize(cmd: String):
    if history.is_empty() || cmd != history.get(0):
        history.push_front(cmd);
        reset_history_idx();

func overwrite_text(new_text: String, update_autocomplete: bool):
    set_text(new_text);                  
    await get_tree().process_frame;
    set_caret_column(get_text().length());
    if update_autocomplete:
        autocomplete.update(new_text);
