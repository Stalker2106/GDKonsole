extends RichTextLabel

var scroll_container : ScrollContainer;
var logfile : FileAccess;

func _ready():
    open_logfile();
    scroll_container = get_parent();
    push_paragraph(HORIZONTAL_ALIGNMENT_LEFT);

func open_logfile():
    if !GDKonsole.constants.enable_log_to_file:
        return; # Logfile disabled
    # Open and create if not existing
    if !FileAccess.file_exists(GDKonsole.constants.logfile_path):
        logfile = FileAccess.open(GDKonsole.constants.logfile_path, FileAccess.WRITE_READ);
    else:
        logfile = FileAccess.open(GDKonsole.constants.logfile_path, FileAccess.READ_WRITE);
    # Seek end, if opening failed, disable logging to file
    if logfile != null:
        logfile.seek_end();
    else:
        GDKonsole.write_error("Error: could not open logfile. logs won't be saved for this session.");
        GDKonsole.constants.enable_log_to_file = false;

func write(msg: String = "", color: Color = GDKonsole.colors.default):
    # Remove lines exceeding quota
    while get_line_count() > GDKonsole.constants.max_lines:
        remove_paragraph(0);
    var formatted_msg = msg;
    # Apply color if needed
    if color != GDKonsole.colors.default:
        formatted_msg = "[color=%s]%s[/color]" % [color.to_html(false), msg];
    # Write
    append_text(formatted_msg);
    scroll_to_bottom();
    # Write to logfile if necessary
    if GDKonsole.constants.enable_log_to_file:
        logfile.store_string(strip_bbcode(formatted_msg));

func write_line(msg: String = "", color: Color = GDKonsole.colors.default):
    newline();
    # Write to logfile if necessary
    if GDKonsole.constants.enable_log_to_file:
        logfile.store_8(10); # ASCII for \n
        logfile.flush();
    push_paragraph(HORIZONTAL_ALIGNMENT_LEFT);
    write(msg, color);

func write_texture(tex_path: String):
    write_line("[img]%s[/img]" % tex_path);

# Utils

func scroll_to_bottom():
    # For some reason we have to wait 2 frames
    await get_tree().process_frame;
    await get_tree().process_frame;
    scroll_container.scroll_vertical = scroll_container.get_v_scroll_bar().max_value;

func strip_bbcode(source: String) -> String:
    var regex = RegEx.new();
    regex.compile("\\[.+?\\]");
    return regex.sub(source, "", true);
