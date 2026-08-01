"""
Room

Rooms are simple containers that has no location of their own.

"""

from collections.abc import Mapping

from commands.links import command_choices, command_link
from evennia.objects.objects import DefaultRoom

from .objects import ObjectParent


class Room(ObjectParent, DefaultRoom):
    """
    Rooms are like any Object, except their location is None
    (which is default). They also use basetype_setup() to
    add locks so they cannot be puppeted or picked up.
    (to change that, use at_object_creation instead)

    See mygame/typeclasses/objects.py for a list of
    properties and methods available on all Objects.
    """

    def get_display_exits(self, looker, **kwargs):
        """以中文列出可见出口。"""

        exits = self.filter_visible(self.contents_get(content_type="exit"), looker, **kwargs)
        names = "、".join(
            command_link(exit_obj.key, exit_obj.get_display_name(looker, **kwargs))
            for exit_obj in exits
        )
        return f"|w出口：|n {names}" if names else ""

    def get_display_characters(self, looker, **kwargs):
        """以中文列出同场人物。"""

        characters = self.filter_visible(
            self.contents_get(content_type="character"), looker, **kwargs
        )
        names = "、".join(
            character.get_display_name(looker, **kwargs) for character in characters
        )
        return f"|w同场人物：|n {names}" if names else ""

    def get_display_things(self, looker, **kwargs):
        """以中文列出房间内物品。"""

        things = self.filter_visible(self.contents_get(content_type="object"), looker, **kwargs)
        names = "、".join(thing.get_display_name(looker, **kwargs) for thing in things)
        return f"|w可见之物：|n {names}" if names else ""

    def get_display_footer(self, looker, **kwargs):
        """显示随地点变化、可点击执行的中文行动。"""

        zone_id = self.db.zone_id
        if zone_id == "moonleaf-terrace":
            local_actions = ["采药"]
        elif zone_id == "hidden-spring":
            local_actions = ["修炼"]
            ritual = self.db.pending_ritual
            leader_id = ritual.get("leader_id") if isinstance(ritual, Mapping) else None
            local_actions.append("见证" if leader_id and leader_id != looker.id else "布阵")
        else:
            local_actions = []
        return f"|w可选行动：|n {command_choices(*local_actions, '指引', '修为')}"
