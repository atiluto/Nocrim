init python:
    import nocrim as ng
    import time as nocrim_time

    def portrait(who, width=440, height=880):
        index = ng.PEOPLE[who]["face"]
        # Display crop only; the original generated atlas is retained unchanged.
        return Transform(Crop((index * 443, 0, 443, 887), "images/cast.png"), xysize=(width, height))

    class MountainRoutes(renpy.Displayable):
        def __init__(self, owned, **kwargs):
            super(MountainRoutes, self).__init__(**kwargs)
            self.owned = owned
        def render(self, width, height, st, at):
            r = renpy.Render(1040, 650)
            c = r.canvas()
            for name, data in ng.REGIONS.items():
                for other in data["links"]:
                    if name < other:
                        active = name in self.owned and other in self.owned
                        color = (193, 203, 147, 230) if active else (172, 192, 177, 155)
                        c.line(color, data["pos"], ng.REGIONS[other]["pos"], 4 if active else 3)
            return r

    def perform(command):
        action = command[0]
        kw = command[1] if len(command) > 1 else {}
        next_state, result = ng.apply(store.campaign, action, **kw)
        store.campaign = next_state
        store.last_result = result
        if not result["ok"]:
            renpy.notify(result["text"])
        return result

    speakers = {
        "you": Character("강현", color="#e3c486"),
        "yeon": Character("담연화", color="#98c5a0"),
        "seo": Character("서하린", color="#dd9590"),
        "yun": Character("윤서령", color="#adbce1"),
        "so": Character("백소하", color="#b5d1cf"),
        "n": Character(None),
    }

define narrator = Character(None)
define _game_menu_screen = "pause_menu"
default campaign = None
default last_result = None
default chosen_region = "dal"
default selected_person = "yeon"
default selected_squad = ["you", "yeon"]
default viewed_event = None
default event_line = None
default event_index = 0
default persistent.endings = []

image mountains = Transform("images/mountains.png", xysize=(1600, 900))
image black = Solid("#071210")

label start:
    $ campaign = ng.new_game(int(nocrim_time.time_ns() % 4294967295))
    $ chosen_region = "dal"
    $ selected_person = "yeon"
    $ selected_squad = ["you", "yeon"]
    scene mountains
    with Dissolve(.6)
    jump campaign_loop

label campaign_loop:
    $ _skipping = None
    $ save_name = "%s일 · 산채 %s/8 · %s" % (campaign["turn"], len(campaign["owned"]), ng.REGIONS[campaign["location"]]["name"])
    if campaign["finished"]:
        jump campaign_ending
    if campaign["queue"]:
        $ viewed_event = campaign["queue"][0]
        call story_event from _call_story_event
        jump campaign_loop
    if campaign["battle"]:
        call screen battle_board
        $ perform(_return)
        if last_result.get("outcome"):
            call screen result_board(last_result) 
        jump campaign_loop
    scene mountains
    call screen campaign_board
    $ command = _return
    if command is None:
        jump campaign_loop
    if command[0] == "sortie":
        $ selected_squad = [p for p in campaign["roster"] if not campaign["wounds"].get(p, 0)][:3]
        call screen sortie_board(command[1]["target"])
        if _return:
            $ perform(_return)
    elif command[0] == "finale_menu":
        call screen finale_board
        if _return:
            $ perform(_return)
    else:
        $ perform(command)
        if last_result.get("vignette"):
            call quiet_moment(last_result["vignette"]) from _call_quiet_moment
        elif command[0] == "end_turn":
            call screen result_board(last_result)
            $ renpy.force_autosave()
    jump campaign_loop

label story_event:
    scene mountains
    show screen story_portrait(ng.EVENTS[viewed_event]["person"])
    show screen chapter_card(ng.EVENTS[viewed_event]["chapter"], ng.EVENTS[viewed_event]["title"])
    with Dissolve(.3)
    $ event_index = 0
    while event_index < len(ng.EVENTS[viewed_event]["lines"]):
        $ event_line = ng.EVENTS[viewed_event]["lines"][event_index]
        $ speakers[event_line[0]](event_line[1])
        $ event_index += 1
    hide screen chapter_card
    call screen event_choices(viewed_event)
    $ perform(("choice", {"event": viewed_event, "index": _return}))
    hide screen story_portrait
    with Dissolve(.2)
    return

label quiet_moment(who):
    scene mountains
    show screen story_portrait(who)
    with Dissolve(.2)
    if who == "yeon":
        $ speakers["yeon"]("같이 순찰 돌자. 말만 듣는 것하고 직접 보는 건 다르니까.")
        $ speakers["you"]("현장 체험 좋지. 근데 경사도 실화냐. 비술로 올라가면 안 됨?")
        $ speakers["yeon"]("네가 직접 걸어야 다른 사람이 얼마나 힘든지 알지.")
    elif who == "seo":
        $ speakers["seo"]("오늘 도착한 표물이에요. 분실 없음, 부상 없음. 이런 날은 장부가 짧아서 좋아요.")
        $ speakers["you"]("무사고 인증은 개추지. …잘했다는 뜻이야.")
    elif who == "yun":
        $ speakers["yun"]("손목에 힘을 빼라. 이길 생각보다 검을 놓치지 않을 생각부터 해.")
        $ speakers["you"]("뉴비 튜토리얼 친절하네. 내일도 가능?")
        $ speakers["yun"]("내일도 살아서 돌아오면.")
    else:
        $ speakers["so"]("안 아픈데도 오셨네요. 차라도 드릴까요?")
        $ speakers["you"]("정기 검진임. 정신 건강 포함해서.")
        $ speakers["so"]("그럼 약 대신 이야기를 좀 하죠.")
    hide screen story_portrait
    return

label campaign_ending:
    $ ending_id = campaign["finished"]
    if ending_id not in persistent.endings:
        $ persistent.endings = persistent.endings + [ending_id]
        $ renpy.save_persistent()
    scene mountains
    with Dissolve(.8)
    show screen chapter_card(ng.ENDINGS[ending_id][1], ng.ENDINGS[ending_id][0])
    $ narrator(ng.ENDINGS[ending_id][2])
    hide screen chapter_card
    if ending_id not in ("fall", "home"):
        python:
            for who in campaign["bonds"]:
                renpy.show_screen("story_portrait", who)
                epilogue = {
                    "yeon": "담연화는 총채주 관저 대신 솔바람채의 낡은 부엌을 고쳤다. 두 사람은 높은 자리에 오르는 대신 같은 식탁에 앉았다. 매일 돌아오겠다는 약속에는, 이제 돌아갈 사람이 있었다.",
                    "seo": "서하린의 계약서 마지막 장에는 운임도 기간도 없었다. 다만 ‘함께 귀환할 것’이라는 조항이 남았다. 먼 길의 끝마다 두 사람은 서로의 무사함을 먼저 확인했다.",
                    "yun": "윤서령은 족보에 새 직함을 올리지 않았다. 강현과 함께 산길을 걸을 때만 검을 반대편에 찼다. 나란히 걷는 사람의 손을 비워 두기 위해서였다.",
                    "so": "백소하의 약방은 밤마다 조금 일찍 문을 닫았다. 병이 없어도 만날 이유가 생겼다. 돌아갈 길을 연구하던 두 사람은, 남아 있을 이유를 더 많이 알고 있었다.",
                }[who]
                narrator(epilogue)
                renpy.hide_screen("story_portrait")
            friendship_endings = {
                "yeon": "담연화는 부채주의 자리를 지켰다. 연인으로 맺어지지는 않았지만, 가장 어려운 명령을 내리기 전 강현이 의견을 묻는 사람은 늘 그녀였다. 두 사람의 식탁에는 동료들이 함께 앉았다.",
                "seo": "서하린은 해동표국의 국주가 되었다. 강현과의 공동 운송 계약은 해마다 갱신되었다. 사사로운 약속 대신 정직한 장부를 주고받는 두 사람은, 강호에서 가장 오래가는 동업자가 되었다.",
                "yun": "윤서령은 자신의 이름으로 검을 들었다. 혼자 떠날 수 있게 된 뒤에도 때때로 솔바람채를 찾았다. 강현은 묻지 않고 연무장을 비워 두었다. 벗을 맞는 데에는 가문의 허락이 필요하지 않았다.",
                "so": "백소하는 안개재의 약방을 지켰다. 강현이 진료 핑계로 들르면 늘 찻잔을 하나 더 놓았다. 함께 연구하고 때때로 침묵하는 사이에도 이름을 붙일 수 있다는 것을, 두 사람은 알고 있었다.",
            }
            for who in ("yeon", "seo", "yun", "so"):
                if campaign["flags"].get(who + "_friend"):
                    renpy.show_screen("story_portrait", who)
                    narrator(friendship_endings[who])
                    renpy.hide_screen("story_portrait")
    elif ending_id == "home" and campaign["bonds"]:
        "약속을 나눈 이들에게 작별을 고했다. 귀환은 그 약속의 해피엔딩이 아니었다. 남겨진 사람들은 기다리는 대신 각자의 산길을 계속 걸었다."
    call screen ending_board(ending_id)
    return
