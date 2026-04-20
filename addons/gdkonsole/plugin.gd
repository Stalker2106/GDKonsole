@tool
extends EditorPlugin


func _enable_plugin() -> void:
    self.add_autoload_singleton("GDKonsole", get_script().resource_path.get_base_dir()+"/console/gdkonsole.gd");
    # Add toggle action
    if not InputMap.has_action("gdkonsole_toggle"):
        InputMap.add_action("gdkonsole_toggle", 0.5);

func _disable_plugin() -> void:
    self.remove_autoload_singleton("GDKonsole");
    # Remove toggle action
    if not InputMap.has_action("gdkonsole_toggle"):
        InputMap.erase_action("gdkonsole_toggle");

func _enter_tree():
    pass;

func _exit_tree():
    pass;
