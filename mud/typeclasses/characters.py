"""
Characters

Characters are (by default) Objects setup to be puppeted by Accounts.
They are what you "see" in game. The Character class in this module
is setup to be the "default" character type created by the default
creation commands.

"""

from evennia.objects.objects import DefaultCharacter

from .objects import ObjectParent


class Character(ObjectParent, DefaultCharacter):
    """
    The Character just re-implements some of the Object's methods and hooks
    to represent a Character entity in-game.

    See mygame/typeclasses/objects.py for a list of
    properties and methods available on all Object child classes like this.

    """

    def at_object_creation(self):
        """Create a new mortal with explicit, server-owned cultivation state."""

        super().at_object_creation()
        from world.rules import Cultivator

        self.db.cultivation = Cultivator().to_dict()
        self.db.cultivation_events = []
        self.db.foraged_sites = []

    def at_post_puppet(self, **kwargs):
        """进入角色时显示中文提示与当前位置。"""

        self.msg(f"\n你进入山河，化身为 |c{self.key}|n。\n")
        if not self.location:
            return
        self.msg((self.at_look(self.location), {"type": "look"}), options=None)

        def announce(character, from_obj):
            character.msg(
                f"{self.get_display_name(character)}踏入了此地。",
                from_obj=from_obj,
            )

        self.location.for_contents(announce, exclude=[self], from_obj=self)

    def announce_move_from(
        self, destination, msg=None, mapping=None, move_type="move", **kwargs
    ):
        """向原地点播报中文离开消息。"""

        super().announce_move_from(
            destination,
            msg=msg or "{object}离开此地，前往{destination}。",
            mapping=mapping,
            move_type=move_type,
            **kwargs,
        )

    def announce_move_to(
        self, source_location, msg=None, mapping=None, move_type="move", **kwargs
    ):
        """向新地点播报中文到达消息。"""

        super().announce_move_to(
            source_location,
            msg=msg or "{object}从{origin}来到此地。",
            mapping=mapping,
            move_type=move_type,
            **kwargs,
        )
