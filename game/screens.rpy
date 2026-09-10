screen main_menu():
    tag menu
    add "mountains"
    add Solid("#07161266")
    frame:
        background Solid("#081a18c9")
        xpos 105 ypos 92 xsize 600 ysize 700
        padding (55, 45)
        vbox:
            spacing 18
            text "NOCRIM  /  산을 잇고, 인연을 맺다" style "caption_text"
            null height 8
            text "녹림전생" size 88 color "#ecd7ae"
            text "어쩌다 보니 총채주" size 30 color "#bed0c3"
            null height 8
            text "일어났더니 채주였다.\n밥을 먹이려 산을 먹었다.\n정신을 차렸더니 천하가 걸려 있었다." size 24 line_spacing 10
            null height 24
            textbutton "처음부터  ·  무림 접속" action Start() xfill True
            textbutton "기록 불러오기" action ShowMenu("load") xfill True
            hbox:
                spacing 10
                textbutton "이야기 수첩" action ShowMenu("collection")
                textbutton "설정" action ShowMenu("preferences")
                textbutton "종료" action Quit(confirm=True)
    text "첫 산의 선택이, 마지막 인연을 바꾼다." xpos 1015 ypos 785 size 24 color "#e2d2af"
    text "0.1  ·  팔산 통일편" xpos 105 ypos 836 style "caption_text"

screen topbar():
    frame:
        xpos 0 ypos 0 xsize 1600 ysize 102
        background Solid("#0a1917f5")
        padding (34, 19)
        hbox:
            spacing 32
            vbox:
                text "녹림전생" size 30 color "#e6d0a4"
                text "제 [campaign['turn']]일 · 초가을" size 18 color "#a9beb0"
            use resource_cell("명령", "%s / 3" % campaign["ap"])
            use resource_cell("은전", "%s 냥" % campaign["gold"])
            use resource_cell("군량", str(campaign["rice"]))
            use resource_cell("병력", str(campaign["troops"]))
            use resource_cell("민심 / 위세", "%s / %s" % (campaign["mercy"], campaign["fear"]))
            use resource_cell("귀산 · 전음", "%s / %s" % (campaign["qi"], campaign["qi_max"]))
            textbutton "기록 · 설정" action ShowMenu("pause_menu") yalign .5

screen resource_cell(title, value):
    vbox:
        spacing 4
        text title style "caption_text"
        text value size 26 color "#e2dcc6"

screen campaign_board():
    default tab = "map"
    add "mountains"
    add Solid("#071c198c")
    use topbar
    frame:
        xpos 0 ypos 102 xsize 1600 ysize 68
        padding (22, 5)
        background Solid("#132724ee")
        hbox:
            spacing 7
            textbutton "산하도" style "nav_button" action SetScreenVariable("tab", "map") selected tab == "map"
            textbutton "산채 경영" style "nav_button" action SetScreenVariable("tab", "manage") selected tab == "manage"
            textbutton "인물 · 등용" style "nav_button" action SetScreenVariable("tab", "people") selected tab == "people"
            textbutton "강호록" style "nav_button" action SetScreenVariable("tab", "journal") selected tab == "journal"
            textbutton "길잡이" style "nav_button" action ShowMenu("help")
    if tab == "map":
        use world_map
    elif tab == "manage":
        use management
    elif tab == "people":
        use people_board
    else:
        use journal_board
    frame:
        xpos 0 ypos 809 xsize 1600 ysize 91
        background Solid("#0b1b19f5")
        padding (34, 15)
        hbox:
            spacing 20
            vbox:
                xsize 1110
                text "주둔  [ng.REGIONS[campaign['location']]['name']]   /   산채 [len(campaign['owned'])]/8   /   사기 [campaign['morale']]" size 21 color "#e5d3af"
                text (campaign["log"][-1] if campaign["log"] else "인접한 산채를 선택해 정찰하거나 출전하세요.") size 18 color "#adbbb1" xmaximum 1100
            textbutton "마지막 선택" action Return(("finale_menu", {})) sensitive any(ng.finale_options(campaign).values())
            textbutton "하루 마감  →" action Return(("end_turn", {})) background Solid("#9e7849") hover_background Solid("#c29a63")

screen world_map():
    fixed:
        xpos 10 ypos 170 xsize 1050 ysize 635
        add MountainRoutes(campaign["owned"])
        text "팔산도  八山圖" xpos 30 ypos 24 size 36 color "#ded1ac"
        text "선을 따라 진군하고, 점령한 산을 비술로 잇는다." xpos 32 ypos 70 style "caption_text"
        for key, data in ng.REGIONS.items():
            $ owned = key in campaign["owned"]
            $ reachable = key in ng.frontier(campaign)
            $ selected = key == chosen_region
            button:
                xpos data["pos"][0] ypos data["pos"][1]
                anchor (.5, .5)
                xsize 175 ysize 90
                background Solid("#876a43f0" if selected else "#234937ef" if owned else "#182b2cf0")
                hover_background Solid("#4f6753f5")
                padding (12, 8)
                action SetVariable("chosen_region", key)
                vbox:
                    xalign .5
                    text data["name"] size 25 xalign .5 color "#f0e2c5"
                    text ("주둔 중" if campaign["location"] == key else "점령 · 비술 연결" if owned else "진군 가능" if reachable else "태백 봉쇄" if key == "tae" else "연결되지 않음") size 16 xalign .5 color "#bbd2c1"
        text "녹림의 산     ━  점령한 길     ━  진군로" xpos 30 ypos 593 style "caption_text"
    $ place = ng.REGIONS[chosen_region]
    frame:
        xpos 1090 ypos 192 xsize 475 ysize 591
        padding (30, 27)
        vbox:
            spacing 13
            text place["faction"] style "caption_text"
            text place["name"] size 46 color "#e6cfa2"
            text place["title"] size 23 color "#bdcdbf"
            null height 2
            text place["lore"] size 23 line_spacing 9
            null height 8
            if chosen_region in campaign["owned"]:
                text "수입  +[place['income']]냥 / 일" size 23 color "#d9c391"
                text "주둔 시 이 산의 수비력 +30" style "small_text"
                textbutton "귀산술 · 이 산으로 순간이동" action Return(("teleport", {"target":chosen_region})) sensitive campaign["qi"] > 0 and chosen_region != campaign["location"] xfill True
                textbutton "전음 · 원격 보급 지휘" action Return(("communicate", {"target":chosen_region})) sensitive campaign["qi"] > 0 and chosen_region != campaign["location"] and chosen_region not in campaign["communicated"] xfill True
                text "비술 1 사용 · 명령 소모 없음\n전음: 군량 +18, 사기 +3 / 하루 한 번" style "caption_text"
            else:
                text "적 전력  [place['strength']]    수입  +[place['income']]냥" size 22 color "#d9c391"
                text ("정찰 완료 · 기습 정보 확보" if chosen_region in campaign["scouted"] else "정찰하면 기습에 쓸 정보를 얻습니다.") style "small_text"
                textbutton "정찰  ·  명령 1 / 은전 10" action Return(("scout", {"target":chosen_region})) sensitive chosen_region in ng.frontier(campaign) and campaign["ap"] > 0 and campaign["gold"] >= 10 and chosen_region not in campaign["scouted"] xfill True
                textbutton "출전 편성  →" action Return(("sortie", {"target":chosen_region})) sensitive chosen_region in ng.frontier(campaign) and campaign["ap"] > 0 xfill True
                if chosen_region == "tae" and not campaign["flags"].get("council"):
                    text "산채 여섯 곳을 점령한 뒤 회의를 열면 태백으로 진군할 수 있습니다." style "caption_text"

screen management():
    frame:
        xpos 35 ypos 192 xsize 960 ysize 587
        padding (32, 25)
        vbox:
            spacing 20
            text "산을 다스리는 일" style "title_text"
            text "사람을 모으고, 함께 먹고, 다음 싸움을 준비한다." size 23 color "#b4c8bb"
            grid 2 3:
                spacing 14
                use management_action("모병", "병력 +45 · 은전 -30", "levy", 30)
                use management_action("군량 구입", "군량 +70 · 은전 -20", "supply", 20)
                use management_action("합동 훈련", "숙련 +10 · 사기 +5 · 은전 -15", "drill", 15)
                use management_action("휴식", "사기 +18 · 부상 1일 회복", "rest", 0)
                use management_action("마을 구휼", "민심 +8 · 위세 -5 · 은전 -20", "amnesty", 20)
                frame:
                    xsize 433 ysize 111 background Solid("#192e28")
                    vbox:
                        text "모든 내정은 명령 1 사용" size 24 color "#dbc292"
                        text "남은 명령은 다음 날로 넘어가지 않습니다." size 19
    frame:
        xpos 1020 ypos 192 xsize 545 ysize 587
        vbox:
            spacing 22
            text "오늘의 살림" style "title_text"
            text "산채 수입     +[ng.income(campaign)]냥 / 일" size 26
            text "군량 생산     +[len(campaign['owned']) * 16] / 일" size 26
            text "군량 소비     -[ng.upkeep(campaign)] / 일" size 26
            text "부대 숙련     [campaign['training']] / 80" size 26
            text "사기             [campaign['morale']] / 100" size 26
            bar value campaign["morale"] range 100
            text "군량이 부족하면 병사가 이탈하고 사기가 떨어집니다.\n\n토벌이 시작된 뒤에는 사흘마다 침공이 옵니다. 민심과 병력을 유지하고, 위태로운 산에 주둔하세요." size 22 color "#b6c8bb"

screen management_action(title, desc, cmd, cost):
    button:
        xsize 433 ysize 111
        action Return((cmd, {}))
        sensitive campaign["ap"] > 0 and campaign["gold"] >= cost
        vbox:
            spacing 7
            text title size 28 color "#e1cfaa"
            text desc size 21

screen people_board():
    frame:
        xpos 35 ypos 192 xsize 342 ysize 588
        padding (18, 20)
        viewport:
            mousewheel True draggable True scrollbars "vertical"
            vbox:
                spacing 8
                for p in campaign["roster"] + [p for p in campaign["met"] + campaign["prisoners"] if p not in campaign["roster"]]:
                    button:
                        xsize 289
                        selected selected_person == p
                        action SetVariable("selected_person", p)
                        vbox:
                            text ng.PEOPLE[p]["name"] size 26
                            text ("포로" if p in campaign["prisoners"] else "동료" if p in campaign["roster"] else "재야") + " · " + ng.PEOPLE[p]["role"] size 18 color "#b3c8b9"
    $ person = ng.PEOPLE[selected_person]
    if person["face"] >= 0:
        add portrait(selected_person, 293, 586) xpos 405 ypos 192
    else:
        frame:
            xpos 405 ypos 192 xsize 293 ysize 586
            vbox:
                align (.5, .5)
                spacing 20
                text person["name"] size 42 color "#d8c099" xalign .5
                text person["role"] size 22 xalign .5
    frame:
        xpos 725 ypos 192 xsize 840 ysize 587
        padding (32, 24)
        vbox:
            spacing 16
            text "[person['name']]  ·  [person['age']]세" size 39 color person["color"]
            text person["role"] style "caption_text"
            text person["bio"] size 25 line_spacing 9
            text "무력 [person['might']]    지략 [person['wit']]    부상 [campaign['wounds'].get(selected_person, 0)]일" size 23 color "#dcc393"
            if selected_person in campaign["aff"]:
                $ rel = campaign["aff"][selected_person]
                text "인연 [rel]/100  ·  [ng.relation_name(rel)]" size 24
                bar value rel range 100
                text ("마음을 확인한 사이" if selected_person in campaign["bonds"] else "인연 사건: 20 / 40 / 65에서, 약속에 따라 열립니다.") style "caption_text"
                hbox:
                    spacing 12
                    textbutton "교류 · 명령 1" action Return(("talk", {"who":selected_person})) sensitive campaign["ap"] > 0 and selected_person not in campaign["talked"]
                    if selected_person not in campaign["roster"]:
                        textbutton "등용 · 은전 30" action Return(("recruit", {"who":selected_person})) sensitive campaign["ap"] > 0
            elif selected_person in campaign["prisoners"]:
                text "포로 처우는 되돌릴 수 없는 인연의 갈림길입니다." style "small_text"
                hbox:
                    spacing 12
                    textbutton "등용 제안 · 명령 1" action Return(("recruit", {"who":selected_person})) sensitive campaign["ap"] > 0
                    textbutton "석방 · 민심 +10 / 몸값 +20" action Show("release_confirm", who=selected_person) sensitive campaign["ap"] > 0
                text "기본 비용 30냥. 범무진: 위세 30 또는 민심 45.\n하도겸: 적송 보호 약속 또는 민심 55.\n석방하면 이번 회차에는 다시 등용할 수 없습니다." style "caption_text"
            else:
                text "출전 편성에서 함께 싸울 인원을 고를 수 있습니다." size 23 color "#b6cbbd"

screen release_confirm(who):
    modal True
    zorder 150
    add Solid("#0009")
    frame:
        align (.5, .5) xsize 750
        vbox:
            spacing 25
            text "[ng.PEOPLE[who]['name']]를 돌려보낼까요?" size 32 color "#e4cda0"
            text "민심 +10, 몸값 +20. 이번 회차에는 등용할 수 없습니다." size 24
            hbox:
                spacing 20
                textbutton "석방한다" action [Hide("release_confirm"), Return(("release", {"who":who}))]
                textbutton "더 생각한다" action Hide("release_confirm")

screen journal_board():
    frame:
        xpos 35 ypos 192 xsize 1000 ysize 587
        vbox:
            spacing 16
            text "강호에 남은 기록" style "title_text"
            viewport:
                ysize 450 mousewheel True draggable True scrollbars "vertical"
                vbox:
                    spacing 15
                    for line in reversed(campaign["log"]):
                        text line size 22 xmaximum 915
    frame:
        xpos 1060 ypos 192 xsize 505 ysize 587
        vbox:
            spacing 18
            text "내가 만든 갈림길" size 34 color "#e1c69a"
            text "점령 순서" style "caption_text"
            text (" → ".join(ng.REGIONS[r]["name"] for r in campaign["order"]) or "아직 솔바람채뿐이다.") size 24
            text "경험한 사건  [len(campaign['seen'])]" size 25
            text "인연 성립  [len(campaign['bonds'])]" size 25
            if campaign["flags"].get("early_iron"):
                text "철마산 첫 점령 · 기연의 길" size 23 color "#e3c48b"
            if campaign["flags"].get("trade"):
                text "해동표국과 공동 운송" size 23 color "#a9cfb3"
            if campaign["flags"].get("seek_home"):
                text "백운령에서 고향의 신호 발견" size 23 color "#b3c8de"
            text "어떤 선택은 다른 사건을 닫습니다.\n모든 이야기를 한 회차에서 볼 수는 없습니다." style "small_text"

screen sortie_board(target):
    modal True
    add "mountains"
    add Solid("#061916df")
    frame:
        align (.5, .5) xsize 1190 ysize 755
        padding (40, 35)
        vbox:
            spacing 22
            text "[ng.REGIONS[target]['name']] 출전 편성" style "title_text"
            text "최대 세 명을 선택하세요. 출전 시 명령 1과 군량 25를 사용합니다." size 24
            hbox:
                spacing 20
                text "아군 전력 [ng.power(campaign, selected_squad)]" size 28 color "#bddba9"
                text "적 전력 [ng.REGIONS[target]['strength']]" size 28 color "#daa095"
                text "선택 [len(selected_squad)] / 3" size 28 color "#ddc89b"
            viewport:
                ysize 340 mousewheel True draggable True scrollbars "vertical"
                vbox:
                    spacing 8
                    for p in campaign["roster"]:
                        $ wound = campaign["wounds"].get(p, 0)
                        textbutton ("✓ " if p in selected_squad else "  ") + ng.PEOPLE[p]["name"] + "  /  " + ng.PEOPLE[p]["role"] + ("  · 부상 %s일" % wound if wound else ""):
                            action Function(toggle_squad, p)
                            selected p in selected_squad
                            sensitive not wound and (p in selected_squad or len(selected_squad) < 3)
                            xsize 1070
            text "기습은 정보 1이 필요합니다. 철마산의 첫 합에는 지휘부 포박 기회가 있습니다.\n돌격은 허공격, 방어는 돌격, 허공격은 방어 대형에 강합니다." size 21 color "#acbfb1"
            hbox:
                spacing 16
                textbutton "진군한다" action Return(("attack", {"target":target, "squad":selected_squad})) sensitive bool(selected_squad) and campaign["rice"] >= 25 and campaign["troops"] >= 30
                textbutton "지도 돌아가기" action Return(None)

init python:
    def toggle_squad(who):
        squad = list(store.selected_squad)
        if who in squad:
            squad.remove(who)
        elif len(squad) < 3:
            squad.append(who)
        store.selected_squad = squad

screen battle_board():
    $ b = campaign["battle"]
    add "mountains"
    add Solid("#0a101bbb")
    frame:
        xpos 80 ypos 55 xsize 1440 ysize 128
        hbox:
            spacing 65
            vbox:
                text "[ng.REGIONS[b['target']]['name']] 공략" size 43 color "#e1c9a0"
                text "제 [b['round']]합 / 5합 · 다섯 합 뒤 남은 전열로 승패 결정" size 22 color "#b3c6b9"
            text "정보 [campaign['intel']]" size 30 yalign .5
            text "적의 예고: " + {"rush":"돌격 대형", "guard":"방어 대형", "feint":"허공격 대형"}[b["intent"]] size 28 color "#e0aca0" yalign .5
    frame:
        xpos 80 ypos 212 xsize 650 ysize 243
        vbox:
            spacing 18
            text "솔바람군  /  전력 [b['own']]" size 30 color "#c0d9b0"
            text " · ".join(ng.PEOPLE[p]["name"] for p in b["squad"]) size 25
            text "전열 [b['hp']] / 100" size 25
            bar value b["hp"] range 100
    frame:
        xpos 765 ypos 212 xsize 755 ysize 243
        vbox:
            spacing 18
            text "[ng.REGIONS[b['target']]['faction']]  /  전력 [b['enemy']]" size 30 color "#dfb1a4"
            text "[ng.REGIONS[b['target']]['title']]" size 25
            text "전열 [b['enemy_hp']] / 100" size 25
            bar value b["enemy_hp"] range 100 left_bar Solid("#bf8072")
    frame:
        xpos 80 ypos 482 xsize 1440 ysize 205
        vbox:
            spacing 7
            for line in b["log"][-4:]:
                text line size 23
    hbox:
        xpos 80 ypos 721 spacing 14
        use tactic_button("돌격", "허공격에 강함", "assault")
        use tactic_button("방어", "돌격에 강함", "guard")
        use tactic_button("허공격", "방어에 강함", "feint")
        use tactic_button("기습", "정보 1 · 큰 피해", "ambush")
        use tactic_button("퇴각", "병력 -12 · 재정비", "retreat")
    textbutton "기록 · 설정" xpos 1280 ypos 838 action ShowMenu("pause_menu")

screen tactic_button(title, desc, move):
    button:
        xsize 277 ysize 106
        action Return(("tactic", {"move":move}))
        sensitive move != "ambush" or campaign["intel"] > 0
        vbox:
            spacing 7
            text title size 31 color "#e2cca3"
            text desc size 21

screen story_portrait(who):
    if ng.PEOPLE[who]["face"] >= 0:
        add portrait(who, 530, 1060) xpos 955 ypos 25

screen chapter_card(chapter, title):
    frame:
        xpos 75 ypos 65 xmaximum 875
        padding (25, 18)
        background Solid("#0e2621d9")
        vbox:
            spacing 6
            text chapter size 20 color "#a8c1b1"
            text title size 33 color "#e6d0a8"

screen say(who, what):
    window:
        id "window"
        if who is not None:
            text who id "who"
        text what id "what" ypos (48 if who is not None else 0)
    hbox:
        xpos 110 ypos 860 spacing 16
        textbutton "기록" style "nav_button" text_size 18 action ShowMenu("history")
        textbutton "저장" style "nav_button" text_size 18 action ShowMenu("save")
        textbutton "불러오기" style "nav_button" text_size 18 action ShowMenu("load")
        textbutton "자동" style "nav_button" text_size 18 action Preference("auto-forward", "toggle")
        textbutton "설정" style "nav_button" text_size 18 action ShowMenu("preferences")

screen event_choices(event_id):
    $ ev = ng.EVENTS[event_id]
    $ eligibility = ng.available_choices(campaign, event_id)
    frame:
        xpos 85 yalign .70 xsize 1130
        padding (30, 25)
        vbox:
            spacing 18
            text ev["title"] size 35 color "#e5cfa5"
            for index, option in enumerate(ev["choices"]):
                button:
                    style "choice_button"
                    action Return(index)
                    sensitive eligibility[index]
                    vbox:
                        spacing 7
                        text option["text"] size 27 color ("#f2e2c6" if eligibility[index] else "#899387")
                        text option["hint"] size 21 color "#b4cbbc"
            text "선택은 점령 이후의 관계와 사건에 남습니다." style "caption_text"

screen choice(items):
    frame:
        align (.5, .65) xsize 1080
        vbox:
            spacing 15
            for item in items:
                textbutton item.caption style "choice_button" action item.action

screen result_board(result):
    modal True
    add Solid("#061815d9")
    frame:
        align (.5, .5) xsize 1100
        padding (40, 35)
        vbox:
            spacing 25
            text ("전장 보고" if result.get("outcome") else "하루가 저물었다") style "title_text"
            text result["text"] size 29 line_spacing 10
            for line in result.get("combat_log", [])[-5:]:
                text line size 22 color "#b1c6b8"
            textbutton "계속" action Return() xalign 1.0

screen finale_board():
    modal True
    add Solid("#061815e8")
    $ opts = ng.finale_options(campaign)
    frame:
        align (.5, .5) xsize 1140
        vbox:
            spacing 22
            text "마지막으로, 어느 길을 택할까" style "title_text"
            textbutton "총채주가 된다  ·  여덟 산 점령" action Return(("finale", {"method":"unify"})) sensitive opts["unify"] xfill True
            textbutton "산들의 연맹을 세운다  ·  6산 / 연맹 선언 / 표국 / 윤가 / 민심 60" action Return(("finale", {"method":"federation"})) sensitive opts["federation"] xfill True
            textbutton "현대로 돌아간다  ·  백운령과 태백 / 귀환 연구" action Return(("finale", {"method":"home"})) sensitive opts["home"] xfill True
            text "통일 결말은 민심·위세와 철마산 첫 점령 여부에 따라 달라집니다.\n결말을 고르기 전까지 교류와 남은 사건을 계속할 수 있습니다." size 24
            textbutton "아직 할 일이 남았다" action Return(None)

screen ending_board(ending_id):
    add Solid("#091b17c9")
    frame:
        align (.5, .5) xsize 1130
        padding (45, 40)
        vbox:
            spacing 25
            text ng.ENDINGS[ending_id][1] size 25 color "#a9c0af"
            text ng.ENDINGS[ending_id][0] size 51 color "#ecd4a5"
            text "[campaign['turn']]일  ·  산채 [len(campaign['owned'])]/8  ·  사건 [len(campaign['seen'])]개  ·  인연 [len(campaign['bonds'])]명" size 27
            text "처음 먹은 산이 달랐다면, 다른 사람의 손을 잡았다면.\n그곳에는 아직 보지 못한 이야기가 남아 있습니다." size 26 line_spacing 12
            textbutton "수첩에 이 이야기를 남긴다" action Return() xalign 1.0

screen pause_menu():
    tag menu
    add "mountains"
    add Solid("#061715b9")
    frame:
        align (.5, .5) xsize 690
        vbox:
            spacing 14
            text "잠시, 산바람을 듣는다" size 40 color "#e5cda0"
            textbutton "계속하기" action Return() xfill True
            textbutton "저장" action ShowMenu("save") xfill True
            textbutton "불러오기" action ShowMenu("load") xfill True
            textbutton "설정" action ShowMenu("preferences") xfill True
            textbutton "길잡이" action ShowMenu("help") xfill True
            textbutton "처음 화면" action MainMenu() xfill True
            textbutton "종료" action Quit() xfill True

screen menu_shell(title):
    add "mountains"
    add Solid("#091b18df")
    text title xpos 95 ypos 54 size 47 color "#e3cda4"
    textbutton "돌아가기" xpos 1310 ypos 52 action Return()
    transclude

screen save():
    tag menu
    use file_slots("산중 기록 · 저장")

screen load():
    tag menu
    use file_slots("산중 기록 · 불러오기")

screen file_slots(title):
    use menu_shell(title):
        hbox:
            xpos 95 ypos 139 spacing 12
            textbutton "자동" action FilePage("auto")
            for page in range(1, 5):
                textbutton str(page) action FilePage(page)
        grid 3 2:
            xpos 95 ypos 215 spacing 24
            for i in range(1, 7):
                button:
                    xsize 454 ysize 270
                    action FileAction(i)
                    has vbox
                    spacing 12
                    add FileScreenshot(i) xsize 405 ysize 177
                    text FileTime(i, format="%Y.%m.%d  %H:%M", empty="비어 있는 기록") size 22
                    text FileSaveName(i) size 19
        text "기록을 선택하면 저장하거나 불러옵니다. 하루 마감 시 자동 저장됩니다." xpos 95 ypos 828 size 23 color "#b3c6b8"

screen preferences():
    tag menu
    use menu_shell("설정"):
        frame:
            xpos 95 ypos 166 xsize 1100
            vbox:
                spacing 30
                text "화면" size 29 color "#e4cda4"
                hbox:
                    spacing 15
                    textbutton "창 모드" action Preference("display", "window")
                    textbutton "전체 화면" action Preference("display", "fullscreen")
                text "대사 표시 속도" size 29 color "#e4cda4"
                bar value Preference("text speed") xsize 900
                text "자동 진행 대기 시간" size 29 color "#e4cda4"
                bar value Preference("auto-forward time") xsize 900
                text "마우스 / Enter: 진행 · Esc: 메뉴 · 휠 위 / Page Up: 대사 되감기\nTab: 읽은 대사 건너뛰기 · F: 전체 화면" size 24 line_spacing 10
                text "이 버전은 음성·배경음 없이 구성되어 있습니다." size 22 color "#aabfb0"

screen history():
    tag menu
    use menu_shell("지나간 대사"):
        viewport:
            xpos 95 ypos 160 xsize 1390 ysize 665
            mousewheel True draggable True scrollbars "vertical"
            vbox:
                spacing 28
                for h in _history_list:
                    vbox:
                        spacing 9
                        if h.who:
                            text h.who size 26 color "#d7be93"
                        text h.what size 26 xmaximum 1330 substitute False

screen help():
    tag menu
    use menu_shell("솔바람채 생존 수첩"):
        viewport:
            xpos 95 ypos 158 xsize 1390 ysize 690
            mousewheel True draggable True scrollbars "vertical"
            vbox:
                spacing 23
                for heading, body in [
                    ("01  하루 세 번의 명령", "정찰·출전·내정·교류·등용은 명령 1을 씁니다. 하루를 마감하면 수입과 군량을 정산하고 명령과 비술을 회복합니다. 군량 구입으로 기근을 피하세요."),
                    ("02  산을 잇는 비술", "귀산술은 이미 점령한 산으로만 이동합니다. 주둔하면 그 산의 수비력 +30. 다른 점령 산에 전음하면 명령 소모 없이 군량 +18, 사기 +3을 얻습니다. 둘 다 비술 1을 씁니다."),
                    ("03  약한 산, 혹은 첫날의 강적", "달개울채는 안정적인 첫 공략입니다. 철마산은 처음부터 도전할 수 있습니다. 정찰하면 정보와 약점을 확보하며, 다른 산을 먹기 전 첫 합의 기습에는 26% 확률로 적장 포박이 발생합니다."),
                    ("04  다섯 합의 전투", "최대 세 명을 편성합니다. 적 대형 예고를 보고 방어→돌격, 돌격→허공격, 허공격→방어 상성을 활용하세요. 정보 1로 기습할 수 있습니다. 다섯 합 후 아군 전열이 더 많아도 승리합니다. 패전은 재도전할 수 있습니다."),
                    ("05  사람을 얻는 법", "포로는 등용 또는 석방할 수 있습니다. 재야 인물은 교류로 관계 20을 쌓으면 등용할 수 있습니다. 네 인물의 개인 사건은 관계 20·40·65에서 열리지만, 마지막 사건은 앞서 한 약속을 지켜야 합니다."),
                    ("06  주변 세력의 반응", "달개울 점령은 표국, 청학산 점령은 윤가, 안개재 점령은 의원과 이어집니다. 점령 순서와 약탈 장부·흑기·공동 운송 선택에 따라 다른 사건을 만납니다."),
                    ("07  토벌과 패망", "기본 9일째 토벌 예고, 11일째부터 3일마다 침공합니다. 철마산 첫 점령 시 각각 5일과 7일로 당겨집니다. 유예를 사면 침공이 4일 늦어집니다. 마지막 산에서 세 번 방어에 실패하면 패망합니다."),
                    ("08  마지막 선택", "6개 산을 모으면 태백이 열립니다. 8개 산 점령은 통일, 표국·윤가·민심을 모으면 연맹, 백운령의 연구와 태백 점령은 귀환으로 이어집니다. 통일은 위세와 민심, 철마산 첫 점령에 따라 세 갈래입니다."),
                    ("09  저장과 다른 선택", "하루 마감은 자동 저장됩니다. 메뉴에서 수동 저장도 가능합니다. 같은 기록을 불러오면 난수도 유지됩니다. 단순 불러오기만으로 기습 결과가 바뀌지는 않습니다."),
                ]:
                    text heading size 29 color "#e3c997"
                    text body size 25 xmaximum 1310 line_spacing 8

screen collection():
    tag menu
    use menu_shell("이야기 수첩"):
        viewport:
            xpos 95 ypos 158 xsize 1390 ysize 690
            mousewheel True draggable True scrollbars "vertical"
            vbox:
                spacing 18
                text "여덟 산, 여섯 결말. 그리고 네 사람과의 인연." size 29 color "#d8c79f"
                for key, data in ng.ENDINGS.items():
                    frame:
                        xsize 1320
                        vbox:
                            spacing 6
                            text (data[0] if key in persistent.endings else "아직 쓰이지 않은 이야기") size 29 color "#e1ceaa"
                            text (data[1] if key in persistent.endings else "다른 선택으로 길을 열어 보세요.") size 22 color "#a9c3b1"
                text "각본·시스템·인물: 이 프로젝트의 오리지널 설정\n배경·초상: AI 생성 원화 · 엔진: Ren’Py · 글꼴: Source Han Sans (SIL OFL)" size 21 color "#9eb7a7"

screen confirm(message, yes_action, no_action):
    modal True
    zorder 200
    add Solid("#000a")
    frame:
        align (.5, .5) xsize 800
        vbox:
            spacing 30
            text message size 28
            hbox:
                spacing 22
                textbutton "확인" action yes_action
                textbutton "취소" action no_action
    key "game_menu" action no_action

screen notify(message):
    zorder 180
    frame:
        xalign .5 ypos 175 xmaximum 1200
        background Solid("#294c40f9")
        text message style "notify_text"
    timer 4.0 action Hide("notify")

screen input(prompt):
    window:
        vbox:
            spacing 25
            text prompt
            input id "input"
