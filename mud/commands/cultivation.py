"""Evennia command adapters for the cultivation vertical slice."""

from __future__ import annotations

from collections.abc import Iterable
from typing import Any, ClassVar

from world.rules import (
    Cultivator,
    Ritual,
    RuleEvent,
    RuleViolationError,
    complete_ritual,
    cultivate,
    forage,
    prepare_ritual,
)

from commands.command import Command

ERROR_MESSAGES = {
    "no_resource": "此地没有可采集的月芽草。 / No moonleaf grows here.",
    "already_foraged": "你已采过此处本轮生长的灵草。 / You already foraged this site.",
    "thin_qi": "此地灵气太薄，无法完成引息。 / The local qi is too thin to cultivate.",
    "wrong_ritual_site": "共鸣阵只能在藏泉灵脉布置。 / The formation requires the hidden spring.",
    "self_witness": "布阵者不能为自己见证。 / A leader cannot witness their own formation.",
    "ritual_moved": "阵式与当前灵脉不再相合。 / The formation is bound to another site.",
    "leader_absent": "布阵者已不在此处，阵式自行消散。 / The leader has left; the formation fades.",
}


def load_state(character: Any) -> Cultivator:
    return Cultivator.from_mapping(character.db.cultivation)


def persist(character: Any, state: Cultivator, events: Iterable[RuleEvent]) -> None:
    character.db.cultivation = state.to_dict()
    audit = list(character.db.cultivation_events or [])
    audit.extend(event.to_dict() for event in events)
    character.db.cultivation_events = audit


def explain_error(character: Any, error: RuleViolationError) -> None:
    character.msg(ERROR_MESSAGES[error.code])


class CmdCultivationStatus(Command):
    """Show cultivation state. Usage: cultivation | status | 状态"""

    key = "cultivation"
    aliases: ClassVar[list[str]] = ["status", "状态", "修为"]
    locks = "cmd:all()"
    help_category = "Cultivation"

    def func(self) -> None:
        state = load_state(self.caller)
        self.caller.msg(
            f"|w{self.caller.key}|n · {state.realm}\n"
            f"灵气 Qi: {state.qi}/{3 if state.realm == '凡身' else '∞'} · "
            f"月芽草 Moonleaf: {state.moonleaf} · 悟性 Insight: {state.insight}\n"
            f"因果 Karma: {state.karma} · 寿元 Lifespan: {state.lifespan}"
        )


class CmdForage(Command):
    """Gather a local spirit herb. Usage: forage | 采药"""

    key = "forage"
    aliases: ClassVar[list[str]] = ["采药", "gather"]
    locks = "cmd:all()"
    help_category = "Cultivation"

    def func(self) -> None:
        site_id = str(self.caller.location.db.zone_id or self.caller.location.id)
        visited = set(self.caller.db.foraged_sites or [])
        try:
            outcome = forage(
                load_state(self.caller),
                actor_id=self.caller.id,
                resource=self.caller.location.db.resource,
                already_foraged=site_id in visited,
            )
        except RuleViolationError as error:
            explain_error(self.caller, error)
            return
        visited.add(site_id)
        self.caller.db.foraged_sites = sorted(visited)
        persist(self.caller, outcome.state, outcome.events)
        self.caller.msg("你采得一株月芽草。 / You gather one moonleaf herb.")


class CmdCultivate(Command):
    """Refine local spiritual energy. Usage: cultivate | 修炼"""

    key = "cultivate"
    aliases: ClassVar[list[str]] = ["修炼", "meditate"]
    locks = "cmd:all()"
    help_category = "Cultivation"

    def func(self) -> None:
        before = load_state(self.caller)
        try:
            outcome = cultivate(
                before,
                actor_id=self.caller.id,
                ambient_qi=self.caller.location.db.ambient_qi or 0,
            )
        except RuleViolationError as error:
            explain_error(self.caller, error)
            return
        persist(self.caller, outcome.state, outcome.events)
        if outcome.state.realm != before.realm:
            self.caller.location.msg_contents(
                f"{self.caller.key}气息内敛，初次引灵入脉。 / "
                f"{self.caller.key} opens a first meridian and enters {outcome.state.realm}."
            )
        else:
            self.caller.msg(
                f"你炼化灵气，修为增至 {outcome.state.qi}。 / "
                f"You refine qi; progress is now {outcome.state.qi}."
            )


class CmdPrepareRitual(Command):
    """Prepare a formation for another player to witness. Usage: prepare | 布阵"""

    key = "prepare"
    aliases: ClassVar[list[str]] = ["布阵", "prepare formation"]
    locks = "cmd:all()"
    help_category = "Cultivation"

    def func(self) -> None:
        location = self.caller.location
        try:
            ritual = prepare_ritual(
                leader_id=self.caller.id,
                room_id=str(location.db.zone_id or location.id),
                zone=location.db.zone_id,
            )
        except RuleViolationError as error:
            explain_error(self.caller, error)
            return
        location.db.pending_ritual = ritual.to_dict()
        location.msg_contents(
            f"{self.caller.key}以石灯定住泉眼，等待另一位修行者见证。 / "
            f"{self.caller.key} prepares a resonance formation; another player may witness."
        )


class CmdWitness(Command):
    """Complete another player's prepared formation. Usage: witness | 见证"""

    key = "witness"
    aliases: ClassVar[list[str]] = ["见证", "join formation"]
    locks = "cmd:all()"
    help_category = "Cultivation"

    def func(self) -> None:
        location = self.caller.location
        raw_ritual = location.db.pending_ritual
        if not raw_ritual:
            self.caller.msg("此处没有待见证的阵式。 / No formation awaits a witness.")
            return
        try:
            ritual = Ritual.from_mapping(raw_ritual)
        except ValueError:
            location.db.pending_ritual = None
            self.caller.msg("阵式记录已损坏，安全消散。 / Invalid formation data was cleared.")
            return
        leader = next((obj for obj in location.contents if obj.id == ritual.leader_id), None)
        try:
            outcome = complete_ritual(
                ritual,
                witness_id=self.caller.id,
                room_id=str(location.db.zone_id or location.id),
                leader_present=leader is not None,
                leader=load_state(leader) if leader else Cultivator(),
                witness=load_state(self.caller),
            )
        except RuleViolationError as error:
            if error.code in {"leader_absent", "ritual_moved"}:
                location.db.pending_ritual = None
            explain_error(self.caller, error)
            return
        persist(leader, outcome.leader, outcome.events)
        persist(self.caller, outcome.witness, outcome.events)
        location.db.pending_ritual = None
        location.msg_contents(
            f"{leader.key}与{self.caller.key}共振灵脉，各得两缕灵气与一点悟性。 / "
            "The formation resolves: both cultivators gain two qi and one insight."
        )


class CmdPath(Command):
    """Show the playable vertical-slice path. Usage: path | 指引"""

    key = "path"
    aliases: ClassVar[list[str]] = ["指引", "journey"]
    locks = "cmd:all()"
    help_category = "Cultivation"

    def func(self) -> None:
        self.caller.msg(
            "|w照禾县引息试炼 / Zha he Initiation|n\n"
            "1. 从渡口向 east 采药 (forage)。\n"
            "2. 向 west 返回，再 north 入藏泉。\n"
            "3. 修炼 (cultivate)，灵草会助你引息。\n"
            "4. 一人布阵 (prepare)，另一人见证 (witness)。\n"
            "5. 用状态 (status) 查看境界、灵气、悟性与寿元。"
        )
