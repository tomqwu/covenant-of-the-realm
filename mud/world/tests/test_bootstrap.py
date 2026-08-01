"""World construction tests."""

from evennia import create_object, search_object
from evennia.settings_default import BASE_ROOM_TYPECLASS
from evennia.utils.test_resources import EvenniaTest

from world.bootstrap import build_vertical_slice


class BootstrapTests(EvenniaTest):
    def setUp(self):
        super().setUp()
        self.limbo = create_object(BASE_ROOM_TYPECLASS, key="Limbo")

    def test_build_is_idempotent_and_links_the_authored_rooms(self):
        crossing, terrace, spring = build_vertical_slice()
        rebuilt = build_vertical_slice()

        self.assertEqual(rebuilt, (crossing, terrace, spring))
        self.assertEqual(crossing.db.zone_id, "zhahe-crossing")
        self.assertEqual(crossing.key, "照禾渡口")
        self.assertEqual(terrace.key, "月芽田")
        self.assertEqual(spring.key, "藏泉石室")
        self.assertEqual(terrace.db.resource, "moonleaf")
        self.assertEqual(spring.db.ambient_qi, 3)
        self.assertEqual({exit_obj.key for exit_obj in crossing.exits}, {"东", "北"})
        east = next(exit_obj for exit_obj in crossing.exits if exit_obj.key == "东")
        south = next(exit_obj for exit_obj in spring.exits if exit_obj.key == "南")
        self.assertEqual(east.destination, terrace)
        self.assertEqual(south.destination, crossing)
        self.assertTrue(east.aliases.has("east"))
        self.assertTrue(south.aliases.has("south"))
        displayed_exits = crossing.get_display_exits(self.char1)
        self.assertIn("|lc东|lt东|le", displayed_exits)
        self.assertIn("|lc北|lt北|le", displayed_exits)
        self.assertEqual(len(search_object("moonleaf-terrace", attribute_name="zone_id")), 1)
