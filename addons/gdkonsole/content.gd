extends RichTextLabel

const MAX_LINES = 500;

var scroll_container : ScrollContainer;

func _ready():
    scroll_container = get_parent();
    push_paragraph(HORIZONTAL_ALIGNMENT_LEFT);

func write(msg: String = "", color: Color = GDKonsole.colors.default):
    # Remove lines exceeding quota
    while get_line_count() > MAX_LINES:
        remove_paragraph(0);
    var formatted_msg = msg;
    # Apply color if needed
    if color != GDKonsole.colors.default:
        formatted_msg = "[color=%s]%s[/color]" % [color.to_html(false), msg];
    # Write
    append_text(formatted_msg);
    scroll_to_bottom();

func write_line(msg: String = "", color: Color = GDKonsole.colors.default):
    newline();
    push_paragraph(HORIZONTAL_ALIGNMENT_LEFT);
    write(msg, color);

func scroll_to_bottom():
    # For some reason we have to wait 2 frames
    await get_tree().process_frame;
    await get_tree().process_frame;
    scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value;
