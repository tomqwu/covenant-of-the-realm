"""
Room

Rooms are simple containers that has no location of their own.

"""

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
        names = "、".join(exit_obj.get_display_name(looker, **kwargs) for exit_obj in exits)
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
