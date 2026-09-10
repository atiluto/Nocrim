import copy
import pathlib
import random
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "game" / "python-packages"))
import nocrim as g
from nocrim.engine import conquest, discover

def choose_all(s, index=0):
    while s["queue"]:
        eid = s["queue"][0]
        choices = g.available_choices(s, eid)
        selected = index if index < len(choices) and choices[index] else choices.index(True)
        s, result = g.apply(s, "choice", event=eid, index=selected)
        assert result["ok"], result
    return s

class CampaignTests(unittest.TestCase):
    def fresh(self, seed=7):
        return choose_all(g.new_game(seed))

    def test_atomic_and_deterministic_save_state(self):
        s = self.fresh()
        before = copy.deepcopy(s)
        after, _ = g.apply(s, "scout", target="iron")
        self.assertEqual(s, before)
        import pickle
        restored = pickle.loads(pickle.dumps(after))
        a, _ = g.apply(after, "attack", target="iron", squad=["you", "yeon"])
        b, _ = g.apply(restored, "attack", target="iron", squad=["you", "yeon"])
        self.assertEqual(g.apply(a, "tactic", move="ambush"), g.apply(b, "tactic", move="ambush"))

    def test_first_boss_luck_is_possible_but_not_guaranteed(self):
        wins = 0
        for seed in range(1, 201):
            s = self.fresh(seed)
            s, _ = g.apply(s, "scout", target="iron")
            s, _ = g.apply(s, "attack", target="iron")
            s, r = g.apply(s, "tactic", move="ambush")
            if r.get("outcome") == "win":
                wins += 1
                self.assertIn("iron_early", s["queue"])
                self.assertTrue(s["flags"]["lucky_iron"])
        self.assertGreater(wins, 30)
        self.assertLess(wins, 80)

    def test_capture_order_changes_meetings(self):
        s = self.fresh()
        conquest(s, "dal")
        self.assertIn("dal_first", s["queue"])
        other = self.fresh()
        conquest(other, "iron")
        other = choose_all(other)
        conquest(other, "dal")
        self.assertIn("dal_iron", other["queue"])

    def test_trade_changes_yun_route(self):
        s = self.fresh()
        conquest(s, "crane")
        self.assertIn("crane_alone", s["queue"])
        t = self.fresh()
        conquest(t, "dal")
        t = choose_all(t)
        conquest(t, "crane")
        self.assertIn("crane_trade", t["queue"])

    def test_recapture_does_not_repeat_first_encounter(self):
        s = self.fresh()
        conquest(s, "iron")
        s = choose_all(s)
        s["owned"].remove("iron")
        s["location"] = "sol"
        conquest(s, "iron")
        self.assertFalse(s["queue"])
        self.assertEqual(s["order"], ["iron"])

    def test_teleport_and_communication_require_owned_remote_mountain(self):
        s = self.fresh()
        self.assertFalse(g.apply(s, "teleport", target="iron")[1]["ok"])
        conquest(s, "dal")
        s = choose_all(s)
        ap = s["ap"]
        s, r = g.apply(s, "communicate", target="sol")
        self.assertTrue(r["ok"])
        self.assertEqual(ap, s["ap"])
        self.assertFalse(g.apply(s, "communicate", target="sol")[1]["ok"])
        s, r = g.apply(s, "teleport", target="sol")
        self.assertTrue(r["ok"])
        self.assertEqual(s["location"], "sol")
        self.assertEqual(s["qi"], 1)
        s["owned"].remove("dal")
        self.assertFalse(g.apply(s, "teleport", target="dal")[1]["ok"])

    def test_affection_alone_does_not_unlock_romance(self):
        s = self.fresh()
        s["aff"]["yeon"] = 100
        s["seen"] += ["rel_yeon_1", "rel_yeon_2"]
        s["queue"] = []
        discover(s)
        self.assertNotIn("rel_yeon_3", s["queue"])
        s["flags"].update(yeon_table=True, yeon_promise=True)
        discover(s)
        self.assertIn("rel_yeon_3", s["queue"])

    def test_recruitment_and_release_are_exclusive(self):
        s = self.fresh()
        conquest(s, "dal")
        s = choose_all(s)
        released, r = g.apply(s, "release", who="gil")
        self.assertTrue(r["ok"])
        self.assertFalse(g.apply(released, "recruit", who="gil")[1]["ok"])
        hired, r = g.apply(s, "recruit", who="gil")
        self.assertTrue(r["ok"])
        self.assertIn("gil", hired["roster"])
        self.assertNotIn("gil", hired["prisoners"])
        self.assertFalse(g.apply(hired, "recruit", who="gil")[1]["ok"])

    def test_locked_actions_cannot_spend_or_change_state(self):
        s = self.fresh()
        s["ap"] = 0
        after, r = g.apply(s, "levy")
        self.assertIs(after, s)
        self.assertFalse(r["ok"])
        self.assertFalse(g.apply(s, "attack", target="tae")[1]["ok"])

    def test_squad_validation_and_wounds(self):
        s = self.fresh()
        for squad in ([], ["you", "you"], ["beom"], ["you", "yeon", "seo", "yun"]):
            self.assertFalse(g.apply(s, "attack", target="dal", squad=squad)[1]["ok"])
        s["wounds"]["yeon"] = 2
        self.assertFalse(g.apply(s, "attack", target="dal", squad=["yeon"])[1]["ok"])
        s, _ = g.apply(s, "rest")
        self.assertEqual(s["wounds"]["yeon"], 1)
        s, _ = g.apply(s, "end_turn")
        self.assertEqual(s["wounds"]["yeon"], 0)

    def test_all_six_endings(self):
        s = self.fresh()
        s["owned"] = list(g.REGIONS)
        self.assertEqual(g.ending(s), "benevolent")
        s["flags"]["early_iron"] = True
        self.assertEqual(g.ending(s), "accidental")
        s["fear"] = 100
        self.assertEqual(g.ending(s), "tyrant")
        s["flags"]["seek_home"] = True
        self.assertEqual(g.ending(s, "home"), "home")
        s["flags"].update(federation=True, trade=True, yun_free=True)
        s["mercy"] = 80
        self.assertEqual(g.ending(s, "federation"), "federation")
        self.assertEqual(g.ending(s, "fall"), "fall")

    def test_legitimate_campaign_from_start_to_unification(self):
        s = self.fresh(2381)
        for target in ("dal", "mist", "crane", "iron", "red", "white", "tae"):
            s = choose_all(s)
            # This bot prepares using the same economic actions as the player.
            while s["troops"] < 230 or s["training"] < 40 or s["rice"] < 60:
                if s["ap"] == 0:
                    s, _ = g.apply(s, "end_turn")
                    s = choose_all(s)
                cmd = "levy" if s["troops"] < 230 else "drill" if s["training"] < 40 else "supply"
                if s["gold"] < 30:
                    s, _ = g.apply(s, "end_turn")
                    s = choose_all(s)
                s, r = g.apply(s, cmd)
                self.assertTrue(r["ok"], r)
            if s["ap"] == 0:
                s, _ = g.apply(s, "end_turn")
                s = choose_all(s)
            self.assertIn(target, g.frontier(s))
            s, r = g.apply(s, "attack", target=target, squad=s["roster"][:3])
            self.assertTrue(r["ok"], r)
            while s["battle"]:
                move = {"rush":"guard", "guard":"feint", "feint":"assault"}[s["battle"]["intent"]]
                s, r = g.apply(s, "tactic", move=move)
            self.assertEqual(r["outcome"], "win", (target, r))
        s = choose_all(s)
        s, r = g.apply(s, "finale", method="unify")
        self.assertTrue(r["ok"])
        self.assertIn(s["finished"], ("benevolent", "tyrant", "accidental"))

    def test_long_random_play_preserves_invariants(self):
        rng = random.Random(99)
        for seed in range(20):
            s = self.fresh(seed+1)
            for turn in range(200):
                if s["finished"]:
                    break
                s = choose_all(s)
                if s["battle"]:
                    cmd, kw = "tactic", {"move":rng.choice(["guard", "assault", "feint", "ambush", "retreat"])}
                else:
                    cmd = rng.choice(["attack", "end_turn", "levy", "rest", "scout", "drill", "supply", "amnesty"])
                    kw = {"target":rng.choice(list(g.REGIONS))} if cmd in ("attack", "scout") else {}
                s, r = g.apply(s, cmd, **kw)
                self.assertTrue(0 <= s["ap"] <= 3)
                self.assertTrue(0 <= s["qi"] <= s["qi_max"])
                for key in ("gold", "rice", "troops", "morale", "mercy", "fear", "intel"):
                    self.assertGreaterEqual(s[key], 0, (key, s))
                self.assertIn(s["location"], s["owned"])
                self.assertEqual(len(s["roster"]), len(set(s["roster"])))
                self.assertFalse(set(s["prisoners"]) & set(s["roster"]))

if __name__ == "__main__":
    unittest.main(verbosity=2)
