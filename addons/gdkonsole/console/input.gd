extends LineEdit

const HISTORY_PREV_KEY = KEY_UP;
const HISTORY_NEXT_KEY = KEY_DOWN;

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
    if !visible:
        return; # Do nothing if not visible
    grab_focus();
    var control_pressed = Input.is_key_pressed(KEY_CTRL);
    if event is InputEventKey && event.is_pressed():
        match event.keycode:
            HISTORY_PREV_KEY:
                if history_idx < history.size()-1:
                    history_idx = history_idx + 1;
                    update_history_text();
                get_viewport().set_input_as_handled();
            HISTORY_NEXT_KEY:
                if history_idx >= 0:
                    history_idx = history_idx - 1;
                    update_history_text();
                get_viewport().set_input_as_handled();
            KEY_C:
                if control_pressed:
                    overwrite_text("", true);
                    get_viewport().set_input_as_handled();
            KEY_K:
                if control_pressed:
                    overwrite_text(text.substr(0, get_caret_column()), true);
                    get_viewport().set_input_as_handled();
            KEY_A:
                if control_pressed:
                    overwrite_text(text.substr(0, get_caret_column()), true);
                    get_viewport().set_input_as_handled();
                    

func reset_history_idx(idx = 0):
    history_idx = -1;

func update_history_text():
    if history_idx == -1:
        overwrite_text(temp, true);
    else:
        overwrite_text(history[history_idx], true);

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
