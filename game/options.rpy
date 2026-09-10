define config.name = "녹림전생 — 어쩌다 보니 총채주"
define config.version = "0.1.0"
define config.window_title = "녹림전생 | 어쩌다 보니 총채주"
define config.save_directory = "Nocrim-Original-20260910"
define config.has_sound = False
define config.has_music = False
define config.has_voice = False
define config.history_length = 150
define config.autosave_slots = 5
define config.quicksave_slots = 3
define config.rollback_enabled = True
define config.default_text_cps = 38
define config.default_afm_time = 15
define config.main_menu_music = None
define config.enter_transition = Dissolve(.18)
define config.exit_transition = Dissolve(.18)
define config.intra_transition = Dissolve(.12)
define config.end_game_transition = Dissolve(.5)
define config.window = "auto"
define config.window_show_transition = Dissolve(.15)
define config.window_hide_transition = Dissolve(.15)
define config.allow_underfull_grids = True
define config.check_conflicting_properties = True

init python:
    build.name = "Nocrim"
    build.executable_name = "Nocrim"
    build.directory_name = "Nocrim-0.1.0"
    build.include_update = False
    build.classify(".tools/**", None)
    build.classify(".git/**", None)
    build.classify("releases/**", None)
    build.classify("tests/**", None)
    build.classify("tools/**", None)
    build.classify("game/cache/**", None)
    build.classify("game/saves/**", None)
    build.classify("game/testcases.rpy*", None)
    build.classify("**/__pycache__/**", None)
    build.classify("**/*.pyc", None)
    build.classify("**.bak", None)
    build.classify("**.tmp", None)
    build.classify("log.txt", None)
    build.classify("traceback.txt", None)
    build.classify("errors.txt", None)
    build.classify(".gitignore", None)
    build.classify("lint-report.txt", None)
    build.documentation("README.md")
    build.documentation("docs/**")
