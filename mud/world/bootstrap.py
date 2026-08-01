"""Idempotent creation of the Zhahe County cultivation slice."""

from evennia import create_object, search_object
from evennia.settings_default import BASE_EXIT_TYPECLASS, BASE_ROOM_TYPECLASS


def _room(key: str, zone_id: str, description: str, ambient_qi: int, resource: str | None = None):
    matches = search_object(zone_id, attribute_name="zone_id")
    room = matches[0] if matches else create_object(BASE_ROOM_TYPECLASS, key=key)
    room.key = key
    room.db.zone_id = zone_id
    room.db.desc = description
    room.db.ambient_qi = ambient_qi
    room.db.resource = resource
    return room


def _exit(location, destination, key: str, aliases: list[str]) -> None:
    existing = next(
        (
            exit_obj
            for exit_obj in location.exits
            if exit_obj.key == key or exit_obj.destination == destination
        ),
        None,
    )
    if existing:
        existing.key = key
        existing.destination = destination
        existing.aliases.clear()
        existing.aliases.add(aliases)
        return
    create_object(
        BASE_EXIT_TYPECLASS,
        key=key,
        aliases=aliases,
        location=location,
        destination=destination,
    )


def build_vertical_slice() -> tuple[object, object, object]:
    """Create or repair the three-room slice without duplicating authored objects."""

    default_rooms = search_object("zhahe-crossing", attribute_name="zone_id") or search_object(
        "Limbo"
    )
    if not default_rooms:
        raise RuntimeError("Evennia's default room is missing")
    crossing = default_rooms[0]
    crossing.key = "照禾渡口"
    crossing.db.zone_id = "zhahe-crossing"
    crossing.db.desc = "河水绕过照禾县的石堤。东边是月芽田，北边山道通往藏泉。"
    crossing.db.ambient_qi = 1
    crossing.db.resource = None

    terrace = _room(
        "月芽田",
        "moonleaf-terrace",
        "月白草叶在水气中微微发亮。田埂留有旧规：每位行旅只可取一株。",
        1,
        "moonleaf",
    )
    spring = _room(
        "藏泉石室",
        "hidden-spring",
        "一线灵泉沿石脉涌动。泉眼旁立着两盏无主石灯，可供同修共鸣。",
        3,
    )

    _exit(crossing, terrace, "东", ["east", "e", "月芽田"])
    _exit(terrace, crossing, "西", ["west", "w", "渡口"])
    _exit(crossing, spring, "北", ["north", "n", "藏泉"])
    _exit(spring, crossing, "南", ["south", "s", "渡口"])
    return crossing, terrace, spring
