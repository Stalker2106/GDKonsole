extends Node

func _ready() -> void:
    # DUMMY OBJECTS
    var GameManager = GDScript.new()
    GameManager.source_code = """
extends Node
var cheats_enabled := false
var time_limit := 0
var frag_limit := 30
var friendly_fire := false
var respawn_time := 5.0
"""
    GameManager.reload()

    var ActorManager = GDScript.new()
    ActorManager.source_code = """
extends Node
"""
    ActorManager.reload()

    var Renderer = GDScript.new()
    Renderer.source_code = """
extends Node
var show_fps := false
var crosshair_style := 1
var field_of_view := 90.0
var mouse_sensitivity := 1.0
var view_bobbing := true
var fullbright := false
var draw_world := true
var shadows_enabled := true
var wireframe_mode := false
"""
    Renderer.reload()

    var Server = GDScript.new()
    Server.source_code = """
extends Node
var listen_port := 27015
var max_clients := 16
var tick_rate := 64
"""
    Server.reload()

    var Network = GDScript.new()
    Network.source_code = """
extends Node
"""
    Network.reload()

    var game_manager = GameManager.new()
    var actor_manager = ActorManager.new()
    var renderer = Renderer.new()
    var server = Server.new()
    var network = Network.new()

    add_child(game_manager)
    add_child(actor_manager)
    add_child(renderer)
    add_child(server)
    add_child(network)

    # POPULATE CONSOLE

    # Physics
    GDKonsole.add_cvar("sv_gravity", ProjectSettings, "physics/2d/default_gravity") \
        .set_description("World gravity value")
    GDKonsole.add_cvar("sv_friction", ProjectSettings, "physics/2d/default_friction") \
        .set_description("Ground friction coefficient")
    GDKonsole.add_cvar("sv_maxvelocity", ProjectSettings, "physics/2d/default_linear_damp") \
        .set_description("Maximum velocity cap for all actors")

    # Gameplay
    GDKonsole.add_cvar("sv_cheats", game_manager, "cheats_enabled") \
        .set_description("Master switch for cheat commands")
    GDKonsole.add_cvar("sv_timelimit", game_manager, "time_limit") \
        .set_description("Match time limit in minutes (0 = no limit)")
    GDKonsole.add_cvar("sv_fraglimit", game_manager, "frag_limit") \
        .set_description("Frag limit to end the match (0 = no limit)")
    GDKonsole.add_cvar("sv_friendlyfire", game_manager, "friendly_fire") \
        .set_description("Allow players to damage teammates")
    GDKonsole.add_cvar("sv_respawntime", game_manager, "respawn_time") \
        .set_description("Seconds before a player respawns after death")

    # Client / display
    GDKonsole.add_cvar("cl_showfps", renderer, "show_fps") \
        .set_description("Show FPS counter on screen")
    GDKonsole.add_cvar("cl_crosshair", renderer, "crosshair_style") \
        .set_description("Crosshair style index (0=off, 1=dot, 2=cross, 3=circle)")
    GDKonsole.add_cvar("cl_fov", renderer, "field_of_view") \
        .set_description("Player camera field of view in degrees")
    GDKonsole.add_cvar("cl_sensitivity", renderer, "mouse_sensitivity") \
        .set_description("Mouse look sensitivity multiplier")
    GDKonsole.add_cvar("cl_bobbing", renderer, "view_bobbing") \
        .set_description("Enable weapon and camera view bobbing")

    # Renderer
    GDKonsole.add_cvar("r_fullbright", renderer, "fullbright") \
        .set_description("Disable all lighting, render everything at full brightness")
    GDKonsole.add_cvar("r_drawworld", renderer, "draw_world") \
        .set_description("Toggle world geometry rendering")
    GDKonsole.add_cvar("r_shadows", renderer, "shadows_enabled") \
        .set_description("Enable dynamic shadows")
    GDKonsole.add_cvar("r_wireframe", renderer, "wireframe_mode") \
        .set_description("Render scene in wireframe mode")

    # Network
    GDKonsole.add_cvar("net_port", server, "listen_port") \
        .set_description("Port the server listens on")
    GDKonsole.add_cvar("net_maxclients", server, "max_clients") \
        .set_description("Maximum number of simultaneous clients")
    GDKonsole.add_cvar("net_tickrate", server, "tick_rate") \
        .set_description("Server simulation ticks per second")

    # Commands

    # Player management
    GDKonsole.add_command("kill", actor_manager, "kill_self") \
        .set_description("Instantly kill yourself. Respawn rules apply")

    GDKonsole.add_command("kill_player", actor_manager, "kill_player") \
        .add_argument("player_id", TYPE_INT) \
        .set_description("Kill the player with the given ID")

    GDKonsole.add_command("kill_all", actor_manager, "kill_all_actors") \
        .add_argument("include_player", TYPE_BOOL, false) \
        .set_description("Kill all NPCs in the scene. Pass 1 to also kill the player")

    GDKonsole.add_command("give_health", actor_manager, "give_health") \
        .add_argument("amount", TYPE_INT, 100) \
        .set_description("Give health to the local player")

    GDKonsole.add_command("give_armor", actor_manager, "give_armor") \
        .add_argument("amount", TYPE_INT, 100) \
        .set_description("Give armor to the local player")

    GDKonsole.add_command("give_ammo", actor_manager, "give_ammo") \
        .add_argument("weapon_id", TYPE_INT) \
        .add_argument("amount", TYPE_INT, 50) \
        .set_description("Give ammo for the specified weapon slot")

    GDKonsole.add_command("give_weapon", actor_manager, "give_weapon") \
        .add_argument("weapon_id", TYPE_INT) \
        .set_description("Give the player a weapon by ID")

    GDKonsole.add_command("god", actor_manager, "set_godmode") \
        .add_argument("enable", TYPE_BOOL, true) \
        .set_description("Toggle god mode — player takes no damage")

    GDKonsole.add_command("noclip", actor_manager, "set_noclip") \
        .add_argument("enable", TYPE_BOOL, true) \
        .set_description("Toggle noclip — fly through walls freely")

    GDKonsole.add_command("notarget", actor_manager, "set_notarget") \
        .add_argument("enable", TYPE_BOOL, true) \
        .set_description("Enemies ignore the player completely")

    GDKonsole.add_command("set_speed", actor_manager, "set_player_speed") \
        .add_argument("speed", TYPE_FLOAT, 300.0) \
        .set_description("Override the player movement speed")

    # Game management
    GDKonsole.add_command("map", game_manager, "load_map") \
        .add_argument("map_name", TYPE_STRING) \
        .set_description("Load a map by name, e.g. 'map e1m1'")

    GDKonsole.add_command("restart", game_manager, "restart_map") \
        .set_description("Restart the current map from the beginning")

    GDKonsole.add_command("quit", game_manager, "quit_game") \
        .set_description("Quit the game immediately")

    GDKonsole.add_command("enable_cheats", game_manager, "enable_cheats") \
        .add_argument("enable", TYPE_BOOL, false) \
        .set_description("Allow use of cheat commands this session")

    GDKonsole.add_command("timescale", game_manager, "set_timescale") \
        .add_argument("scale", TYPE_FLOAT, 1.0) \
        .set_description("Set Engine.time_scale. 0.5 = slow motion, 2.0 = fast forward")

    GDKonsole.add_command("spawn", actor_manager, "spawn_actor") \
        .add_argument("actor_name", TYPE_STRING) \
        .add_argument("x", TYPE_FLOAT, 0.0) \
        .add_argument("y", TYPE_FLOAT, 0.0) \
        .set_description("Spawn a named actor at world coordinates (x, y)")

    GDKonsole.add_command("teleport", actor_manager, "teleport_player") \
        .add_argument("x", TYPE_FLOAT) \
        .add_argument("y", TYPE_FLOAT) \
        .set_description("Teleport the player to world coordinates (x, y)")

    # Server / network
    GDKonsole.add_command("kick", server, "kick_player") \
        .add_argument("player_id", TYPE_INT) \
        .add_argument("reason", TYPE_STRING, "Kicked by admin") \
        .set_description("Kick a player from the server by ID")

    GDKonsole.add_command("ban", server, "ban_player") \
        .add_argument("player_id", TYPE_INT) \
        .set_description("Ban a player by ID")

    GDKonsole.add_command("say", server, "broadcast_message") \
        .add_argument("message", TYPE_STRING) \
        .set_description("Broadcast a chat message to all connected players")

    GDKonsole.add_command("status", server, "print_status") \
        .set_description("Print server info: map, players, ping, frags")

    GDKonsole.add_command("changelevel", server, "change_level") \
        .add_argument("map_name", TYPE_STRING) \
        .set_description("Change to a new map without disconnecting players")

    GDKonsole.add_command("net_stats", network, "print_net_stats") \
        .set_description("Print current network statistics: ping, packet loss, bandwidth")

    # Renderer / debug
    GDKonsole.add_command("screenshot", renderer, "take_screenshot") \
        .add_argument("filename", TYPE_STRING, "screenshot") \
        .set_description("Save a screenshot to user:// with the given filename")

    GDKonsole.add_command("r_reload_shaders", renderer, "reload_shaders") \
        .set_description("Hot-reload all shaders without restarting")

    GDKonsole.add_command("r_list_shaders", renderer, "list_shaders") \
        .set_description("Print all currently loaded shaders")
