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
from commands.links import command_choices, command_link

ERROR_MESSAGES = {
    "no_resource": "此地没有可采集的月芽草。",
    "already_foraged": "你已采过此处本轮生长的灵草。",
    "thin_qi": "此地灵气太薄，无法完成引息。",
    "wrong_ritual_site": "共鸣阵只能在藏泉灵脉布置。",
    "self_witness": "布阵者不能为自己见证。",
    "ritual_moved": "阵式与当前灵脉不再相合。",
    "leader_absent": "布阵者已不在此处，阵式自行消散。",
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
    """查看境界与修行资源。用法：修为"""

    key = "修为"
    aliases: ClassVar[list[str]] = ["状态", "status", "cultivation"]
    locks = "cmd:all()"
    help_category = "修行"

    def func(self) -> None:
        state = load_state(self.caller)
        self.caller.msg(
            f"|w{self.caller.key}|n · {state.realm}\n"
            f"灵气：{state.qi}/{3 if state.realm == '凡身' else '∞'} · "
            f"月芽草：{state.moonleaf} · 悟性：{state.insight}\n"
            f"因果：{state.karma} · 寿元：{state.lifespan}\n"
            f"{command_link('查看', '查看地点与可选行动')}"
        )


class CmdForage(Command):
    """采集当地灵草。用法：采药"""

    key = "采药"
    aliases: ClassVar[list[str]] = ["forage", "gather"]
    locks = "cmd:all()"
    help_category = "修行"

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
        self.caller.msg(
            f"你俯身拨开水雾，采得一株月芽草。下一步：{command_link('西', '返回渡口')}"
        )


class CmdCultivate(Command):
    """炼化当地灵气。用法：修炼"""

    key = "修炼"
    aliases: ClassVar[list[str]] = ["cultivate", "meditate"]
    locks = "cmd:all()"
    help_category = "修行"

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
                f"{self.caller.key}气息内敛，初次引灵入脉，踏入{outcome.state.realm}。"
            )
        else:
            self.caller.msg(
                f"你引泉息入脉，灵气积累增至 {outcome.state.qi}。"
                f"可继续：{command_choices('布阵', '修为')}"
            )


class CmdPrepareRitual(Command):
    """布置等待另一位玩家见证的共鸣阵。用法：布阵"""

    key = "布阵"
    aliases: ClassVar[list[str]] = ["prepare", "prepare formation"]
    locks = "cmd:all()"
    help_category = "修行"

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
            f"{self.caller.key}以石灯定住泉眼，布下共鸣阵，等待另一位修行者"
            f"{command_link('见证')}。"
        )


class CmdWitness(Command):
    """见证并完成另一位玩家布置的共鸣阵。用法：见证"""

    key = "见证"
    aliases: ClassVar[list[str]] = ["witness", "join formation"]
    locks = "cmd:all()"
    help_category = "修行"

    def func(self) -> None:
        location = self.caller.location
        raw_ritual = location.db.pending_ritual
        if not raw_ritual:
            self.caller.msg("此处没有等待见证的阵式。")
            return
        try:
            ritual = Ritual.from_mapping(raw_ritual)
        except ValueError:
            location.db.pending_ritual = None
            self.caller.msg("阵式脉络已经紊乱，未生效便自行消散。")
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
            f"{leader.key}与{self.caller.key}共同点亮石灯，灵脉随阵共振；"
            f"二人各得两缕灵气与一点悟性。{command_link('修为', '查看修为')}"
        )


class CmdPath(Command):
    """查看当前可玩的修行路线。用法：指引"""

    key = "指引"
    aliases: ClassVar[list[str]] = ["path", "journey"]
    locks = "cmd:all()"
    help_category = "修行"

    def func(self) -> None:
        self.caller.msg(
            "|w照禾县引息试炼|n\n"
            f"一、从渡口向{command_link('东')}前往月芽田，{command_link('采药')}。\n"
            f"二、向{command_link('西')}返回渡口，再向{command_link('北')}进入藏泉石室。\n"
            f"三、在泉边{command_link('修炼')}；月芽草可助你引息。\n"
            f"四、一人{command_link('布阵')}，另一位同场修行者负责{command_link('见证')}。\n"
            f"五、使用{command_link('修为')}查看境界、灵气、悟性与寿元。"
        )
