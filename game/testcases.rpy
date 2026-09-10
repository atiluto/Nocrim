testsuite global:
    teardown:
        exit

testcase smoke:
    $ _test.transition_timeout = .15
    screenshot "01-title.png"
    click "처음부터"
    advance until screen "event_choices"
    screenshot "02-opening.png"
    click "일단 밥부터 먹이자. 굶긴 채주는 안 한다."
    advance until screen "event_choices"
    click "좋다. 오늘은 내가 한다."
    pause .3
    assert screen "campaign_board"
    screenshot "03-map.png"
    click "산채 경영"
    screenshot "04-management.png"
    click "모병"
    assert eval (campaign["troops"] == 145)
    click "인물 · 등용"
    screenshot "05-people.png"
    click "산하도"
    click "정찰"
    click "출전 편성"
    screenshot "06-sortie.png"
    click "진군한다"
    assert screen "battle_board"
    screenshot "07-battle.png"
    click "퇴각"
    click "계속"
    click "하루 마감"
    click "계속"
    assert eval (campaign["turn"] == 2)
    click "기록 · 설정"
    click "저장"
    pause .5
    screenshot "08-save.png"
    run FileSave(1, confirm=False)
    pause .5
    screenshot "09-saved.png"
    run FileLoad(1, confirm=False)
    pause .5
    assert eval (campaign["turn"] == 2)
    click "산채 경영"
    click "합동 훈련"
    assert eval (campaign["training"] == 10)
    exit

testcase narrative:
    $ _test.transition_timeout = .10
    run Start()
    advance until screen "event_choices"
    click "순간이동에 통신이면"
    pause .3
    assert screen "campaign_board"
    $ campaign = ng.new_game(61)
    $ campaign["queue"] = ["dal_iron", "crane_alone", "rel_so_3"]
    $ campaign["gold"] = 300
    $ campaign["roster"] = ["you", "yeon", "seo", "yun", "so"]
    $ campaign["met"] = ["yeon", "seo", "yun", "so"]
    run Jump("campaign_loop")
    pause .7
    screenshot "10-dialogue.png"
    advance until screen "event_choices"
    click "철마의 약탈 장부를 공개한다"
    advance until screen "event_choices"
    click "마을의 부채를 대신 갚는다"
    advance until screen "event_choices"
    click "아프지 않은 날에도 당신을 만나고 싶어"
    assert eval ("so" in campaign["bonds"])
    click "강호록"
    screenshot "11-journal.png"
    click "길잡이"
    screenshot "12-help.png"
    click "돌아가기"
    click "기록 · 설정"
    click "설정"
    screenshot "13-preferences.png"
    click "돌아가기"
    $ campaign["owned"] = list(ng.REGIONS)
    $ campaign["queue"] = []
    $ campaign["seen"] = list(ng.EVENTS)
    $ campaign["flags"].update(council=True, seek_home=True, federation=True, trade=True, yun_free=True, yeon_friend=True)
    $ campaign["mercy"] = 80
    run Jump("campaign_loop")
    click "마지막 선택"
    screenshot "14-final-choice.png"
    click "총채주가 된다"
    advance until screen "ending_board"
    screenshot "15-ending.png"
    click "수첩에 이 이야기를 남긴다"
    pause .3
    assert screen "main_menu"
    exit
