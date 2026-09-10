init offset = -2
init python:
    gui.init(1600, 900)

define nocrim_font = FontGroup().add("DejaVuSans.ttf", 0x0000, 0x2fff).add("fonts/SourceHanSansLite.ttf", 0x3000, 0xffff)
define gui.text_font = nocrim_font
define gui.name_text_font = nocrim_font
define gui.interface_text_font = nocrim_font
define gui.text_size = 28
define gui.name_text_size = 28
define gui.interface_text_size = 24
define gui.text_color = "#e9e8db"
define gui.interface_text_color = "#e9e8db"
define gui.accent_color = "#d5b77c"
define gui.idle_color = "#b4c6bd"
define gui.hover_color = "#ffe5ad"
define gui.selected_color = "#ffffff"
define gui.insensitive_color = "#708078"
define gui.language = "korean-with-spaces"

style default:
    font nocrim_font
    size 24
    color "#e9e8db"
    language "korean-with-spaces"

style text:
    line_spacing 6

style button:
    background Solid("#172c29e8")
    hover_background Solid("#315049")
    selected_background Solid("#365c4b")
    insensitive_background Solid("#131f1dec")
    padding (18, 12)

style button_text:
    color "#dce7df"
    hover_color "#ffe5ad"
    selected_color "#ffe5ad"
    insensitive_color "#74827a"
    size 22

style frame:
    background Solid("#0f201eed")
    padding (26, 22)

style bar:
    left_bar Solid("#99bfa0")
    right_bar Solid("#2b3e37")
    ysize 8
    thumb None
    thumb_shadow None

style slider:
    left_bar Solid("#d5b77c")
    right_bar Solid("#2b3e37")
    thumb Solid("#f4e4c0", xsize=14, ysize=26)
    ysize 18

style scrollbar:
    base_bar Solid("#253a33")
    thumb Solid("#6f9585")
    ysize 8

style vscrollbar:
    base_bar Solid("#253a33")
    thumb Solid("#6f9585")
    xsize 8

style title_text:
    size 46
    color "#e7d1a5"

style caption_text:
    size 18
    color "#9db5aa"

style small_text:
    size 20
    color "#bccfc4"

style nav_button:
    background None
    hover_background Solid("#29453d")
    selected_background Solid("#29453d")
    padding (23, 12)

style nav_button_text:
    size 24
    color "#c0d0c8"
    selected_color "#efd09a"

style choice_button:
    xfill True
    padding (24, 17)
    background Solid("#19342ff5")
    hover_background Solid("#38584b")

style choice_button_text:
    size 26

style say_window:
    background Solid("#0b1918ee")
    xalign .5
    yalign 1.0
    xsize 1600
    ysize 280
    padding (110, 35, 110, 36)

style say_label:
    size 26
    bold True
    color "#d5b77c"

style say_dialogue:
    size 28
    line_spacing 10
    color "#e9e8db"
    xpos 0
    ypos 48
    xsize 1375

style input:
    color "#f3d59f"
    size 30

style notify_text:
    size 22
    color "#f6e0b4"
