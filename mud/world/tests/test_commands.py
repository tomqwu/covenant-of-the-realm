"""Command-level tests using Evennia's isolated database fixtures."""

from commands.cultivation import (
    CmdCultivate,
    CmdCultivationStatus,
    CmdForage,
    CmdPath,
    CmdPrepareRitual,
    CmdWitness,
    load_state,
)
from evennia.utils.test_resources import EvenniaCommandTest

from world.rules import BREATH_REALM, Cultivator


class CultivationCommandTests(EvenniaCommandTest):
    def setUp(self):
        super().setUp()
        for character in (self.char1, self.char2):
            character.db.cultivation = Cultivator().to_dict()
            character.db.cultivation_events = []
            character.db.foraged_sites = []
        self.room1.db.zone_id = "hidden-spring"
        self.room1.db.ambient_qi = 3
        self.room1.db.resource = None

    def test_status_and_path_explain_the_slice(self):
        self.call(CmdCultivationStatus(), "", "Char · 凡身")
        self.call(CmdPath(), "", "照禾县引息试炼")

    def test_forage_rejects_wrong_site_then_gathers_once(self):
        self.call(CmdForage(), "", "此地没有可采集的月芽草")
        self.room1.db.resource = "moonleaf"
        self.call(CmdForage(), "", "你采得一株月芽草")
        self.assertEqual(load_state(self.char1).moonleaf, 1)
        self.assertEqual(len(self.char1.db.cultivation_events), 1)
        self.call(CmdForage(), "", "你已采过此处本轮生长的灵草")

    def test_cultivate_rejects_thin_qi_then_refines_and_advances(self):
        self.room1.db.ambient_qi = 1
        self.call(CmdCultivate(), "", "此地灵气太薄")
        self.room1.db.ambient_qi = 3
        self.char1.db.cultivation = Cultivator(qi=1, moonleaf=1).to_dict()
        self.call(CmdCultivate(), "", "Char气息内敛")
        state = load_state(self.char1)
        self.assertEqual(state.realm, BREATH_REALM)
        self.assertEqual(state.lifespan, 88)
        self.assertEqual(len(self.char1.db.cultivation_events), 2)

    def test_cultivate_reports_non_breakthrough_progress(self):
        self.call(CmdCultivate(), "", "你炼化灵气，修为增至 1")

    def test_prepare_requires_spring_and_broadcasts_success(self):
        self.room1.db.zone_id = "zhahe-crossing"
        self.call(CmdPrepareRitual(), "", "共鸣阵只能在藏泉灵脉布置")
        self.room1.db.zone_id = "hidden-spring"
        self.call(CmdPrepareRitual(), "", "Char以石灯定住泉眼")
        self.assertEqual(self.room1.db.pending_ritual["leader_id"], self.char1.id)

    def test_witness_handles_missing_corrupt_self_moved_and_absent_rituals(self):
        self.call(CmdWitness(), "", "此处没有待见证的阵式")

        self.room1.db.pending_ritual = {"leader_id": self.char1.id}
        self.call(CmdWitness(), "", "阵式记录已损坏")
        self.assertIsNone(self.room1.db.pending_ritual)

        self.room1.db.pending_ritual = 7
        self.call(CmdWitness(), "", "阵式记录已损坏")
        self.assertIsNone(self.room1.db.pending_ritual)

        self.room1.db.pending_ritual = {
            "leader_id": self.char1.id,
            "room_id": "hidden-spring",
        }
        self.call(CmdWitness(), "", "布阵者不能为自己见证")

        self.room1.db.pending_ritual = {
            "leader_id": self.char2.id,
            "room_id": "another-room",
        }
        self.call(CmdWitness(), "", "阵式与当前灵脉不再相合")
        self.assertIsNone(self.room1.db.pending_ritual)

        self.room1.db.pending_ritual = {"leader_id": 999999, "room_id": "hidden-spring"}
        self.call(CmdWitness(), "", "布阵者已不在此处")
        self.assertIsNone(self.room1.db.pending_ritual)

    def test_two_characters_complete_the_persistent_formation(self):
        self.call(CmdPrepareRitual(), "", "Char以石灯定住泉眼")
        self.call(
            CmdWitness(),
            "",
            "Char与Char2共振灵脉",
            caller=self.char2,
            receiver=self.char2,
        )
        self.assertEqual(load_state(self.char1).qi, 2)
        self.assertEqual(load_state(self.char2).qi, 2)
        self.assertEqual(load_state(self.char1).insight, 1)
        self.assertEqual(load_state(self.char2).insight, 1)
        self.assertEqual(len(self.char1.db.cultivation_events), 1)
        self.assertEqual(len(self.char2.db.cultivation_events), 1)
        self.assertIsNone(self.room1.db.pending_ritual)
