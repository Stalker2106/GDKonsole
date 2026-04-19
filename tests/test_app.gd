extends Control

var command_called : bool = false;
var exec_called : bool = false;
var passing := 0
var failing := 0

var fps;
var cvar_var = 0;

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
    var hint = get_node("Hint");
    var events = InputMap.action_get_events("gdkonsole_toggle");
    if events.size() > 0:
        var key_string = OS.get_keycode_string(events[0].physical_keycode);
        hint.text = hint.text.replace("'KEY'", key_string);
    # Run API Test
    run_api_tests();

func assert_true(value: bool) -> void:
    if value:
        GDKonsole.write_line("PASS", Color.GREEN);
        passing += 1;
    else:
        GDKonsole.write_error("FAIL");
        failing += 1;

func print_summary() -> void:
    GDKonsole.write_line("Results: %d passed, %d failed" % [passing, failing], Color.NAVY_BLUE);

func run_api_tests():
    GDKonsole.write_line("Run API tests", Color.NAVY_BLUE);
    # Test
    GDKonsole.write_line("Test 0: register command");
    var testcmd = GDKonsole.add_command("test", self, "dummycall");
    assert_true(testcmd != null);
    # Test
    GDKonsole.write_line("Test 1: add command description");
    assert_true(testcmd.set_description("I am a test") != null);
    # Test
    GDKonsole.write_line("Test 2: register commands with bad names");
    assert_true(GDKonsole.add_command("dummy command", self, "dummycall") == null);
    # Test
    GDKonsole.write_line("Test 3: register command with arguments");
    assert_true(testcmd.add_argument("arg", TYPE_INT) != null);
    # Test
    GDKonsole.write_line("Test 4: register command with existing name");
    assert_true(GDKonsole.add_command("help", self, "dummycall") == null);
    # Test
    GDKonsole.write_line("Test 5: eval registered command with bad arg type");
    GDKonsole.eval("test ABC");
    assert_true(!command_called);
    # Test
    GDKonsole.write_line("Test 6: eval registered command");
    GDKonsole.eval("test 0");
    assert_true(command_called);
    # Test
    GDKonsole.write_line("Test 7: exec file");
    GDKonsole.add_command("exectest", self, "execcall").add_argument("arg", TYPE_INT);
    GDKonsole.eval("exec tests/exec_test.gd");
    assert_true(exec_called);
    # Test
    GDKonsole.write_line("Test 8: push_error redirect");
    push_error("I am a Godot error");
    assert_true(true);
    # Test
    GDKonsole.write_line("Test 9: register cvar");
    var cvar = GDKonsole.add_cvar("cvar", self, "cvar_var");
    assert_true(cvar != null);
    # Test
    GDKonsole.write_line("Test 9: set cvar");
    GDKonsole.eval("cvar 1");
    assert_true(cvar_var == 1);
    # Summary
    print_summary();
       
func dummycall(_arg):
    if _arg == 0:
        command_called = true;
        
func execcall(_arg):
    if _arg == 42:
        exec_called = true;

func _process(_delta: float) -> void:
    fps = Engine.get_frames_per_second();
