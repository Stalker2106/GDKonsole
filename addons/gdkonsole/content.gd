extends RichTextLabel

const MAX_LINES = 5;

var scroll_container : ScrollContainer;

func _ready():
    scroll_container = get_parent();

func write(msg: String = "", color: Color = GDKonsole.colors.default):
    # Remove lines exceeding quota
    if get_line_count() > MAX_LINES:
        var to_erase = get_line_width(0);
        text.erase(0, to_erase);
    var formatted_msg = msg;
    # Apply color if needed
    if color != GDKonsole.colors.default:
        formatted_msg = "[color=%s]%s[/color]" % [color.to_html(false), msg];
    # Write
    append_text(formatted_msg);
    scroll_to_bottom();

func write_line(msg: String = "", color: Color = GDKonsole.colors.default):
    var text = get_parsed_text();
    if !text.is_empty() && text.right(1) != "\n":
        msg = "\n"+msg;
    write(msg, color);

func scroll_to_bottom():
    # For some reason we have to wait 2 frames
    await get_tree().process_frame;
    await get_tree().process_frame;
    scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value;
