"""Deterministic cultivation rules for the first multiplayer vertical slice.

This module contains no Evennia, database, transport, clock, or random-number access.
Adapters may persist the returned immutable state and events, but only these rules decide
gameplay outcomes.
"""

from __future__ import annotations

from collections.abc import Mapping
from dataclasses import asdict, dataclass, replace
from typing import Any

MORTAL_REALM = "凡身"
BREATH_REALM = "引息境一层"
REALMS = (MORTAL_REALM, BREATH_REALM)
MOONLEAF = "moonleaf"
SPRING_ZONE = "hidden-spring"
BREAKTHROUGH_QI = 3


class RuleViolationError(ValueError):
    """A safe, stable rules error that an adapter can translate into player prose."""

    def __init__(self, code: str) -> None:
        super().__init__(code)
        self.code = code


@dataclass(frozen=True, slots=True)
class Cultivator:
    """Persistent cultivation state owned by one character."""

    realm: str = MORTAL_REALM
    qi: int = 0
    moonleaf: int = 0
    insight: int = 0
    karma: int = 0
    lifespan: int = 80

    def __post_init__(self) -> None:
        if self.realm not in REALMS:
            raise ValueError("unknown realm")
        for value in (self.qi, self.moonleaf, self.insight, self.karma):
            if not isinstance(value, int) or isinstance(value, bool) or value < 0:
                raise ValueError("cultivation resources must be non-negative integers")
        if (
            not isinstance(self.lifespan, int)
            or isinstance(self.lifespan, bool)
            or self.lifespan <= 0
        ):
            raise ValueError("lifespan must be a positive integer")

    @classmethod
    def from_mapping(cls, value: Mapping[str, Any] | None) -> Cultivator:
        """Load stored state, falling back only when no state has ever been stored."""

        if value is None:
            return cls()
        required = {"realm", "qi", "moonleaf", "insight", "karma", "lifespan"}
        if not isinstance(value, Mapping) or set(value) != required:
            raise ValueError("stored cultivation state has an invalid shape")
        return cls(**{field: value[field] for field in required})

    def to_dict(self) -> dict[str, int | str]:
        """Return the JSON-safe representation stored by the server adapter."""

        return asdict(self)


@dataclass(frozen=True, slots=True)
class RuleEvent:
    """An append-only fact emitted by a deterministic transition."""

    kind: str
    actor_ids: tuple[int, ...]
    data: tuple[tuple[str, int | str], ...]
    permanent: bool

    def to_dict(self) -> dict[str, object]:
        return {
            "kind": self.kind,
            "actor_ids": list(self.actor_ids),
            "data": dict(self.data),
            "permanent": self.permanent,
        }


@dataclass(frozen=True, slots=True)
class Outcome:
    state: Cultivator
    events: tuple[RuleEvent, ...]


@dataclass(frozen=True, slots=True)
class Ritual:
    leader_id: int
    room_id: str

    def __post_init__(self) -> None:
        if (
            not isinstance(self.leader_id, int)
            or isinstance(self.leader_id, bool)
            or self.leader_id <= 0
        ):
            raise ValueError("ritual leader id must be a positive integer")
        if not self.room_id.strip():
            raise ValueError("ritual room id is required")

    def to_dict(self) -> dict[str, int | str]:
        return asdict(self)

    @classmethod
    def from_mapping(cls, value: Mapping[str, Any]) -> Ritual:
        if not isinstance(value, Mapping) or set(value) != {"leader_id", "room_id"}:
            raise ValueError("stored ritual has an invalid shape")
        return cls(leader_id=value["leader_id"], room_id=value["room_id"])


@dataclass(frozen=True, slots=True)
class CooperativeOutcome:
    leader: Cultivator
    witness: Cultivator
    events: tuple[RuleEvent, ...]


def forage(
    state: Cultivator,
    *,
    actor_id: int,
    resource: str | None,
    already_foraged: bool,
) -> Outcome:
    """Gather one authored resource at most once per character and site."""

    if resource != MOONLEAF:
        raise RuleViolationError("no_resource")
    if already_foraged:
        raise RuleViolationError("already_foraged")
    updated = replace(state, moonleaf=state.moonleaf + 1)
    event = RuleEvent(
        kind="resource_gathered",
        actor_ids=(actor_id,),
        data=(("resource", MOONLEAF), ("amount", 1)),
        permanent=True,
    )
    return Outcome(updated, (event,))


def cultivate(state: Cultivator, *, actor_id: int, ambient_qi: int) -> Outcome:
    """Convert local spiritual energy and an optional herb into deterministic progress."""

    if not isinstance(ambient_qi, int) or isinstance(ambient_qi, bool) or ambient_qi < 0:
        raise ValueError("ambient qi must be a non-negative integer")
    if ambient_qi < 2:
        raise RuleViolationError("thin_qi")

    herb_bonus = 1 if state.moonleaf else 0
    updated = replace(
        state,
        qi=state.qi + 1 + herb_bonus,
        moonleaf=state.moonleaf - herb_bonus,
    )
    events = [
        RuleEvent(
            kind="qi_refined",
            actor_ids=(actor_id,),
            data=(("amount", 1 + herb_bonus), ("moonleaf_used", herb_bonus)),
            permanent=False,
        )
    ]
    updated, advancement = _advance(updated, actor_id)
    if advancement:
        events.append(advancement)
    return Outcome(updated, tuple(events))


def prepare_ritual(*, leader_id: int, room_id: str, zone: str | None) -> Ritual:
    """Open a cooperative formation only at the authored spring site."""

    if zone != SPRING_ZONE:
        raise RuleViolationError("wrong_ritual_site")
    return Ritual(leader_id=leader_id, room_id=room_id)


def complete_ritual(
    ritual: Ritual,
    *,
    witness_id: int,
    room_id: str,
    leader_present: bool,
    leader: Cultivator,
    witness: Cultivator,
) -> CooperativeOutcome:
    """Resolve the two-player meridian resonance formation."""

    if witness_id == ritual.leader_id:
        raise RuleViolationError("self_witness")
    if ritual.room_id != room_id:
        raise RuleViolationError("ritual_moved")
    if not leader_present:
        raise RuleViolationError("leader_absent")

    leader_updated = replace(leader, qi=leader.qi + 2, insight=leader.insight + 1)
    witness_updated = replace(witness, qi=witness.qi + 2, insight=witness.insight + 1)
    events: list[RuleEvent] = [
        RuleEvent(
            kind="formation_completed",
            actor_ids=(ritual.leader_id, witness_id),
            data=(("qi_each", 2), ("insight_each", 1), ("room", room_id)),
            permanent=True,
        )
    ]
    leader_updated, leader_advancement = _advance(leader_updated, ritual.leader_id)
    witness_updated, witness_advancement = _advance(witness_updated, witness_id)
    if leader_advancement:
        events.append(leader_advancement)
    if witness_advancement:
        events.append(witness_advancement)
    return CooperativeOutcome(leader_updated, witness_updated, tuple(events))


def _advance(state: Cultivator, actor_id: int) -> tuple[Cultivator, RuleEvent | None]:
    if state.realm != MORTAL_REALM or state.qi < BREAKTHROUGH_QI:
        return state, None
    updated = replace(
        state,
        realm=BREATH_REALM,
        qi=state.qi - BREAKTHROUGH_QI,
        insight=state.insight + 1,
        lifespan=state.lifespan + 8,
    )
    return updated, RuleEvent(
        kind="realm_advanced",
        actor_ids=(actor_id,),
        data=(("from", MORTAL_REALM), ("to", BREATH_REALM), ("lifespan_gain", 8)),
        permanent=True,
    )
