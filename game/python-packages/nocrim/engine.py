from copy import deepcopy
from .world import REGIONS, PEOPLE, EVENTS, ENDINGS

def new_game(seed=91723):
    return dict(version=1, seed=int(seed) & 0xffffffff or 1, turn=1, ap=3,
                gold=100, rice=120, troops=100, training=0, morale=70,
                mercy=25, fear=10, intel=0, qi=3, qi_max=3,
                owned=["sol"], order=[], location="sol", roster=["you", "yeon"],
                met=["yeon"], prisoners=[], released=[], wounds={},
                aff={p: (12 if p == "yeon" else 0) for p in ("yeon", "seo", "yun", "so")},
                flags={}, seen=[], queue=["opening"], log=[], battle=None,
                talked=[], communicated=[], scouted=[], siege=0, finished=None, bonds=[])

def roll(s, low=1, high=100):
    # Stored PRNG makes loaded games replay exactly; screens never consume randomness.
    s["seed"] = (1664525 * s["seed"] + 1013904223) & 0xffffffff
    return low + s["seed"] % (high - low + 1)

def frontier(s):
    return [r for r in REGIONS if r not in s["owned"] and
            any(n in s["owned"] for n in REGIONS[r]["links"]) and
            (r != "tae" or s["flags"].get("council"))]

def power(s, squad=None):
    squad = s["roster"][:3] if squad is None else squad
    strength = sum(PEOPLE[p]["might"] * .36 + PEOPLE[p]["wit"] * .12
                   for p in squad if not s["wounds"].get(p, 0))
    return int(12 + strength + min(s["troops"], 420) * .23 + s["training"] * .45 + s["morale"] * .10)

def chance(s, target, squad=None):
    own = power(s, squad)
    enemy = REGIONS[target]["strength"]
    return max(12, min(95, int(50 + (own - enemy) * .75)))

def income(s):
    return sum(REGIONS[r]["income"] for r in s["owned"]) + (12 if s["flags"].get("trade") else 0)

def upkeep(s):
    return 12 + s["troops"] // 12 + len(s["roster"]) * 2

def relation_name(value):
    return "마음이 닿다" if value >= 65 else "신뢰" if value >= 40 else "관심" if value >= 20 else "낯선 사이"

def add_log(s, text):
    s["log"].append("%02d일 · %s" % (s["turn"], text))
    s["log"] = s["log"][-120:]

def queue(s, event_id):
    if event_id not in s["seen"] and event_id not in s["queue"]:
        s["queue"].append(event_id)

def discover(s):
    if s["finished"]:
        return
    if (s["turn"] >= (5 if s["flags"].get("early_iron") else 9)):
        queue(s, "ultimatum")
    if len(s["owned"]) >= 6:
        queue(s, "council")
    for who in s["aff"]:
        if who not in s["roster"]:
            continue
        a = s["aff"][who]
        if a >= 20:
            queue(s, "rel_" + who + "_1")
        if a >= 40 and "rel_" + who + "_1" in s["seen"]:
            queue(s, "rel_" + who + "_2")
        gate = {"yeon":"yeon_table", "seo":"seo_work", "yun":"yun_self", "so":"so_oath"}[who]
        if (a >= 65 and s["flags"].get(who + "_promise") and s["flags"].get(gate)
                and "rel_" + who + "_2" in s["seen"]):
            queue(s, "rel_" + who + "_3")

def available_choices(s, event_id):
    result = []
    for c in EVENTS[event_id]["choices"]:
        ok = all(s.get(key, 0) >= value for key, value in c["requires"].items())
        result.append(ok)
    return result

def effects(s, eff):
    for key, val in eff.items():
        if key.startswith("aff:"):
            who = key[4:]
            s["aff"][who] = max(0, min(100, s["aff"][who] + val))
        elif key.startswith("flag:"):
            s["flags"][key[5:]] = val
        elif key == "join":
            if val not in s["roster"]:
                s["roster"].append(val)
            if val not in s["met"]:
                s["met"].append(val)
        elif key == "meet":
            if val not in s["met"]:
                s["met"].append(val)
        elif key == "bond":
            if val not in s["bonds"]:
                s["bonds"].append(val)
        else:
            s[key] += val
    for key in ("gold", "rice", "troops", "mercy", "fear", "morale", "intel"):
        s[key] = max(0, s[key])
    s["morale"] = min(100, s["morale"])
    s["mercy"] = min(100, s["mercy"])
    s["fear"] = min(100, s["fear"])

def conquest(s, target):
    if target in s["owned"]:
        return
    first = not s["order"]
    recaptured = target in s["order"]
    s["owned"].append(target)
    if not recaptured:
        s["order"].append(target)
    s["location"] = target
    s["gold"] += 25
    s["morale"] = min(100, s["morale"] + 8)
    cap = REGIONS[target]["captive"]
    if cap and cap not in s["roster"] and cap not in s["prisoners"] and cap not in s["released"]:
        s["prisoners"].append(cap)
    event_id = {
        "dal": "dal_iron" if "iron" in s["owned"] else "dal_first",
        "iron": "iron_early" if first else "iron_late",
        "mist": "mist",
        "crane": "crane_trade" if s["flags"].get("trade") else "crane_alone",
        "red": "red_black" if s["flags"].get("black_banner") else "red_plain",
        "white": "white",
    }.get(target)
    if event_id and not recaptured:
        queue(s, event_id)
    add_log(s, REGIONS[target]["name"] + " 점령. 비술의 거점으로 연결되었다.")

def finale_options(s):
    f = s["flags"]
    return {
        "unify": len(s["owned"]) == len(REGIONS),
        "federation": len(s["owned"]) >= 6 and f.get("federation", False) and f.get("trade", False)
                      and f.get("yun_free", False) and s["mercy"] >= 60,
        "home": "white" in s["owned"] and "tae" in s["owned"] and f.get("seek_home", False),
    }

def ending(s, method="unify"):
    if method == "fall":
        return "fall"
    if not finale_options(s).get(method):
        return None
    if method == "home":
        return "home"
    if method == "federation":
        return "federation"
    if s["fear"] > s["mercy"] + 15:
        return "tyrant"
    if s["flags"].get("early_iron"):
        return "accidental"
    return "benevolent"

def apply(state, action, **args):
    """Atomic transition: never mutates an earlier save/rollback state."""
    s = deepcopy(state)
    def fail(text):
        return state, dict(ok=False, text=text)
    def done(text="", **extra):
        discover(s)
        if text:
            add_log(s, text)
        return s, dict(ok=True, text=text, **extra)

    if s["finished"]:
        return fail("이미 막을 내린 이야기입니다.")
    if s["battle"] and action != "tactic":
        return fail("먼저 진행 중인 전투를 마쳐야 합니다.")
    if s["queue"] and action != "choice":
        return fail("도착한 사건의 선택을 먼저 마쳐 주세요.")

    if action == "choice":
        event_id = args.get("event")
        index = args.get("index", -1)
        if not s["queue"] or s["queue"][0] != event_id:
            return fail("현재 사건이 아닙니다.")
        choices = EVENTS[event_id]["choices"]
        if index not in range(len(choices)) or not available_choices(s, event_id)[index]:
            return fail("이 선택에 필요한 자원이 부족합니다.")
        s["queue"].pop(0)
        s["seen"].append(event_id)
        effects(s, choices[index]["effects"])
        return done(EVENTS[event_id]["title"] + " — " + choices[index]["text"])

    if action in ("scout", "levy", "drill", "rest", "talk", "recruit", "release", "attack", "supply", "amnesty") and s["ap"] <= 0:
        return fail("오늘의 명령을 모두 썼습니다. 하루를 마감하세요.")

    if action == "scout":
        target = args.get("target")
        if target not in frontier(s):
            return fail("인접한 적 산채만 정찰할 수 있습니다.")
        if target in s["scouted"]:
            return fail("이미 이 산채의 약점을 확보했습니다.")
        if s["gold"] < 10:
            return fail("정찰에는 은전 10냥이 필요합니다.")
        s["ap"] -= 1
        s["gold"] -= 10
        s["intel"] += 1
        s["scouted"].append(target)
        if target == "iron":
            s["flags"]["iron_weakness"] = True
            return done("철마의 산제 날짜를 알아냈다. 기습 시 첫 합에 26% 확률로 지휘부가 무너진다.")
        return done(REGIONS[target]["name"] + "의 샛길을 찾았다. 기습에 정보 1을 써 큰 피해를 줄 수 있다.")

    if action in ("levy", "drill", "rest", "supply", "amnesty"):
        cost = {"levy":30, "drill":15, "rest":0, "supply":20, "amnesty":20}[action]
        if s["gold"] < cost:
            return fail("은전이 부족합니다.")
        s["ap"] -= 1
        s["gold"] -= cost
        if action == "levy":
            s["troops"] += 45
            return done("의용병 45명이 합류했다. 은전 -30.")
        if action == "drill":
            s["training"] = min(80, s["training"] + 10)
            s["morale"] = min(100, s["morale"] + 5)
            return done("합동 훈련을 마쳤다. 숙련 +10, 사기 +5.")
        if action == "supply":
            s["rice"] += 70
            return done("시장에서 군량 70을 사 왔다. 은전 -20.")
        if action == "amnesty":
            s["mercy"] = min(100, s["mercy"] + 8)
            s["fear"] = max(0, s["fear"] - 5)
            return done("피해 마을을 구휼했다. 민심 +8, 위세 -5.")
        s["morale"] = min(100, s["morale"] + 18)
        s["wounds"] = {p:max(0, w-1) for p, w in s["wounds"].items()}
        return done("부대가 쉬었다. 사기 +18, 부상 회복 1일.")

    if action == "teleport":
        target = args.get("target")
        if target not in s["owned"] or target == s["location"]:
            return fail("현재 위치를 제외한 점령 산채로만 귀산술을 쓸 수 있습니다.")
        if s["qi"] < 1:
            return fail("비술이 고갈되었습니다. 다음 날 회복됩니다.")
        s["qi"] -= 1
        s["location"] = target
        return done("귀산술 · " + REGIONS[target]["name"] + "으로 이동. 명령 소모 없이 이 산의 수비를 직접 지휘한다.")

    if action == "communicate":
        target = args.get("target")
        if target not in s["owned"] or target == s["location"]:
            return fail("현재 위치를 제외한 점령 산채에만 전음할 수 있습니다.")
        if target in s["communicated"] or s["qi"] < 1:
            return fail("이미 오늘 연락했거나 비술이 부족합니다.")
        s["qi"] -= 1
        s["communicated"].append(target)
        s["rice"] += 18
        s["morale"] = min(100, s["morale"] + 3)
        return done("전음 · " + REGIONS[target]["name"] + "의 보급을 조율했다. 군량 +18, 사기 +3, 명령 소모 없음.")

    if action == "talk":
        who = args.get("who")
        if who not in s["met"] or who not in s["aff"]:
            return fail("아직 만난 인물이 아닙니다.")
        if who in s["talked"]:
            return fail("이 인물과는 오늘 이미 시간을 보냈습니다.")
        s["ap"] -= 1
        s["talked"].append(who)
        s["aff"][who] = min(100, s["aff"][who] + (9 if who in s["roster"] else 7))
        return done(PEOPLE[who]["name"] + "와 한 시진을 보냈다. 신뢰가 가까워졌다.", vignette=who)

    if action == "recruit":
        who = args.get("who")
        if who in s["roster"] or who not in s["prisoners"] + s["met"]:
            return fail("지금 등용할 수 없는 인물입니다.")
        cost = 65 if who == "beom" and s["flags"].get("iron_exposed") else 30
        if s["gold"] < cost:
            return fail("등용 비용 %s냥이 필요합니다." % cost)
        if who in s["aff"] and s["aff"][who] < 20:
            return fail("교류로 관계를 20 이상 쌓아야 제안을 받아들입니다.")
        if who == "ha" and not s["flags"].get("red_safe") and s["mercy"] < 55:
            return fail("하도겸은 적송 보호 약속이나 민심 55 이상을 요구합니다.")
        if who == "beom" and s["fear"] < 30 and s["mercy"] < 45:
            return fail("범무진을 설득하려면 위세 30 또는 민심 45 이상이 필요합니다.")
        s["ap"] -= 1
        s["gold"] -= cost
        s["roster"].append(who)
        if who in s["prisoners"]:
            s["prisoners"].remove(who)
        if who not in s["met"]:
            s["met"].append(who)
        return done(PEOPLE[who]["name"] + " 등용. 출전 편성에 추가할 수 있다.")

    if action == "release":
        who = args.get("who")
        if who not in s["prisoners"]:
            return fail("포로가 아닙니다.")
        s["ap"] -= 1
        s["prisoners"].remove(who)
        s["released"].append(who)
        s["mercy"] = min(100, s["mercy"] + 10)
        s["gold"] += 20
        return done(PEOPLE[who]["name"] + "를 돌려보냈다. 민심 +10, 몸값 +20. 이번 회차에는 등용할 수 없다.")

    if action == "attack":
        target = args.get("target")
        squad = args.get("squad", s["roster"][:3])
        if target not in frontier(s):
            return fail("연결된 전선이 아니거나 아직 해금되지 않은 산채입니다.")
        if not 1 <= len(squad) <= 3 or len(set(squad)) != len(squad) or any(p not in s["roster"] or s["wounds"].get(p,0) for p in squad):
            return fail("부상 없는 아군 1~3명을 편성하세요.")
        if s["rice"] < 25 or s["troops"] < 30:
            return fail("출전에는 군량 25와 병력 30 이상이 필요합니다.")
        s["ap"] -= 1
        s["rice"] -= 25
        own = power(s, squad)
        enemy = REGIONS[target]["strength"]
        s["battle"] = dict(target=target, squad=list(squad), round=1, hp=100, enemy_hp=100,
                           own=own, enemy=enemy, guard=False, log=["전투 개시. 적은 " + ("돌격" if enemy % 2 else "방어") + " 대형이다."],
                           intent="rush" if enemy % 2 else "guard")
        return done(REGIONS[target]["name"] + "에 출전했다.")

    if action == "tactic":
        b = s["battle"]
        move = args.get("move")
        if not b or move not in ("assault", "guard", "feint", "ambush", "retreat"):
            return fail("유효한 전술이 아닙니다.")
        if move == "ambush" and s["intel"] < 1:
            return fail("기습에는 정보 1이 필요합니다.")
        if move == "retreat":
            s["troops"] = max(0, s["troops"] - 12)
            s["morale"] = max(0, s["morale"] - 5)
            s["battle"] = None
            return done("퇴각했다. 병력 -12, 사기 -5. 산과 포로는 잃지 않았다.", outcome="retreat")
        lucky = False
        target = b["target"]
        if move == "ambush":
            s["intel"] -= 1
            luck = 26 if s["flags"].get("iron_weakness") else 8
            if target == "iron" and b["round"] == 1 and len(s["owned"]) == 1:
                lucky = roll(s) <= luck
        ratio = b["own"] / b["enemy"]
        damage = 22 * ratio + roll(s, -4, 6)
        received = 22 / max(.25, ratio) + roll(s, -3, 5)
        counter = (move == "guard" and b["intent"] == "rush") or (move == "feint" and b["intent"] == "guard") or (move == "assault" and b["intent"] == "feint")
        if counter:
            damage += 12
            received *= .65
        if move == "guard":
            damage *= .72
            received *= .48
        elif move == "assault":
            damage *= 1.25
            received *= 1.15
        elif move == "ambush":
            damage += 18 + (10 if s["flags"].get("sleep_poison") else 0)
            received *= .72
        damage = max(1, int(damage))
        received = max(1, int(received))
        if lucky:
            damage = 150
            received = 0
            s["flags"]["lucky_iron"] = True
        b["enemy_hp"] = max(0, b["enemy_hp"] - damage)
        b["hp"] = max(0, b["hp"] - received)
        line = "%s합 · 적 피해 %s / 아군 피해 %s%s" % (b["round"], damage, received, " · 전술 적중" if counter else "")
        if lucky:
            line = "산제의 술에 취한 적장이 포박됐다. 말도 안 되는 기습 대성공!"
        b["log"].append(line)
        if b["hp"] <= 0 or b["enemy_hp"] <= 0 or b["round"] >= 5:
            win = b["hp"] > 0 and (b["enemy_hp"] <= 0 or b["hp"] > b["enemy_hp"])
            loss = max(4, int((100 - b["hp"]) * .38)) + (0 if win else 18)
            s["troops"] = max(0, s["troops"] - loss)
            s["battle"] = None
            if win:
                conquest(s, target)
                return done("승리 · " + REGIONS[target]["name"] + " 점령. 병력 -%s." % loss, outcome="win", combat_log=b["log"])
            s["morale"] = max(0, s["morale"] - 12)
            hurt = b["squad"][roll(s, 0, len(b["squad"])-1)]
            s["wounds"][hurt] = 2
            return done("패전 · 병력 -%s. %s 부상 2일. 재정비 후 다시 도전할 수 있다." % (loss, PEOPLE[hurt]["name"]), outcome="lose", combat_log=b["log"])
        b["round"] += 1
        b["intent"] = ("rush", "guard", "feint")[roll(s, 0, 2)]
        return done(line)

    if action == "end_turn":
        s["gold"] += income(s)
        harvest = 16 * len(s["owned"])
        s["rice"] += harvest
        required = upkeep(s)
        shortage = max(0, required - s["rice"])
        s["rice"] = max(0, s["rice"] - required)
        lines = ["수입 +%s냥 / 생산 군량 +%s / 군량 소비 -%s." % (income(s), harvest, required)]
        if shortage:
            s["troops"] = max(0, s["troops"] - shortage)
            s["morale"] = max(0, s["morale"] - 15)
            lines.append("군량이 모자라 %s명이 이탈했다. 사기 -15." % shortage)
        s["turn"] += 1
        s["ap"] = 3
        s["qi"] = s["qi_max"]
        s["talked"] = []
        s["communicated"] = []
        healing = 2 if s["flags"].get("clinic") else 1
        s["wounds"] = {p:max(0, w-healing) for p,w in s["wounds"].items()}
        start = (7 if s["flags"].get("early_iron") else 11) + (4 if s["flags"].get("truce") else 0)
        if s["turn"] >= start and (s["turn"] - start) % 3 == 0:
            possible = [r for r in s["owned"] if any(n not in s["owned"] for n in REGIONS[r]["links"])] or s["owned"]
            target = possible[roll(s,0,len(possible)-1)]
            guard = power(s) * .7 + s["mercy"] * .45 + (30 if s["location"] == target else 0)
            enemy = 60 + s["turn"] * 2 + s["fear"] * .20
            if guard + roll(s,-10,10) >= enemy:
                s["troops"] = max(0, s["troops"]-8)
                lines.append(REGIONS[target]["name"] + " 침공 격퇴. 병력 -8.")
            else:
                s["troops"] = max(0, s["troops"]-24)
                s["morale"] = max(0, s["morale"]-10)
                if len(s["owned"]) > 1:
                    s["owned"].remove(target)
                    if s["location"] == target:
                        s["location"] = s["owned"][0]
                    lines.append(REGIONS[target]["name"] + " 함락. 그 산으로의 비술 연결이 끊겼다.")
                else:
                    s["siege"] += 1
                    lines.append("마지막 산채의 방책이 무너진다. 방어선 %s/3 손실." % s["siege"])
                    if s["siege"] >= 3:
                        s["finished"] = "fall"
        return done(" ".join(lines))

    if action == "finale":
        which = ending(s, args.get("method", "unify"))
        if not which:
            return fail("아직 이 결말의 조건을 갖추지 못했습니다.")
        s["finished"] = which
        return done("이야기의 끝 · " + ENDINGS[which][0])
    return fail("알 수 없는 명령입니다.")
