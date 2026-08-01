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
        self.assertEqual(terrace.db.resource, "moonleaf")
        self.assertEqual(spring.db.ambient_qi, 3)
        self.assertEqual({exit_obj.key for exit_obj in crossing.exits}, {"east", "north"})
        east = next(exit_obj for exit_obj in crossing.exits if exit_obj.key == "east")
        south = next(exit_obj for exit_obj in spring.exits if exit_obj.key == "south")
        self.assertEqual(east.destination, terrace)
        self.assertEqual(south.destination, crossing)
        self.assertEqual(len(search_object("moonleaf-terrace", attribute_name="zone_id")), 1)
