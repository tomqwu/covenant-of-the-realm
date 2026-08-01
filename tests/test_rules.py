"""Exhaustive unit tests for deterministic cultivation rules."""

from __future__ import annotations

import pytest

from mud.world.rules import (
    BREATH_REALM,
    MORTAL_REALM,
    Cultivator,
    Ritual,
    RuleEvent,
    RuleViolationError,
    complete_ritual,
    cultivate,
    forage,
    prepare_ritual,
)


def test_default_state_round_trips() -> None:
    state = Cultivator()
    assert state.to_dict() == {
        "realm": MORTAL_REALM,
        "qi": 0,
        "moonleaf": 0,
        "insight": 0,
        "karma": 0,
        "lifespan": 80,
        "trial_complete": False,
    }
    assert Cultivator.from_mapping(None) == state
    assert Cultivator.from_mapping(state.to_dict()) == state


@pytest.mark.parametrize(
    ("field", "value", "message"),
    [
        ("realm", "unknown", "unknown realm"),
        ("qi", -1, "non-negative integers"),
        ("moonleaf", 1.5, "non-negative integers"),
        ("insight", True, "non-negative integers"),
        ("karma", "1", "non-negative integers"),
        ("lifespan", 0, "positive integer"),
        ("lifespan", True, "positive integer"),
        ("lifespan", 1.5, "positive integer"),
        ("trial_complete", 1, "must be a boolean"),
    ],
)
def test_state_rejects_invalid_values(field: str, value: object, message: str) -> None:
    values = Cultivator().to_dict()
    values[field] = value
    with pytest.raises(ValueError, match=message):
        Cultivator(**values)


def test_stored_state_requires_exact_shape() -> None:
    with pytest.raises(ValueError, match="invalid shape"):
        Cultivator.from_mapping({"realm": MORTAL_REALM})
    with pytest.raises(ValueError, match="invalid shape"):
        Cultivator.from_mapping(7)


def test_stored_legacy_state_migrates_post_breakthrough_overflow() -> None:
    legacy = Cultivator().to_dict()
    legacy.pop("trial_complete")
    assert Cultivator.from_mapping(legacy) == Cultivator()

    legacy.update({"realm": BREATH_REALM, "qi": 35, "lifespan": 88})
    assert Cultivator.from_mapping(legacy) == Cultivator(
        realm=BREATH_REALM, qi=2, lifespan=88
    )

    legacy["qi"] = True
    with pytest.raises(ValueError, match="non-negative integers"):
        Cultivator.from_mapping(legacy)


def test_current_state_rejects_breath_realm_overflow() -> None:
    with pytest.raises(ValueError, match="vertical-slice cap"):
        Cultivator(realm=BREATH_REALM, qi=3, lifespan=88)


def test_rule_violation_exposes_stable_code() -> None:
    error = RuleViolationError("thin_qi")
    assert error.code == "thin_qi"
    assert str(error) == "thin_qi"


def test_event_serializes_json_safe_data() -> None:
    event = RuleEvent("test", (2, 3), (("amount", 1), ("item", "leaf")), True)
    assert event.to_dict() == {
        "kind": "test",
        "actor_ids": [2, 3],
        "data": {"amount": 1, "item": "leaf"},
        "permanent": True,
    }


def test_ritual_round_trips() -> None:
    ritual = Ritual(leader_id=2, room_id="hidden-spring")
    assert ritual.to_dict() == {"leader_id": 2, "room_id": "hidden-spring"}
    assert Ritual.from_mapping(ritual.to_dict()) == ritual


@pytest.mark.parametrize("leader_id", [0, -1, True, "2"])
def test_ritual_rejects_invalid_leader(leader_id: object) -> None:
    with pytest.raises(ValueError, match="positive integer"):
        Ritual(leader_id=leader_id, room_id="hidden-spring")


def test_ritual_rejects_blank_room_and_bad_storage() -> None:
    with pytest.raises(ValueError, match="room id"):
        Ritual(leader_id=2, room_id="  ")
    with pytest.raises(ValueError, match="invalid shape"):
        Ritual.from_mapping({"leader_id": 2})
    with pytest.raises(ValueError, match="invalid shape"):
        Ritual.from_mapping([])


def test_forage_adds_one_herb_and_a_permanent_event() -> None:
    outcome = forage(Cultivator(), actor_id=7, resource="moonleaf", already_foraged=False)
    assert outcome.state.moonleaf == 1
    assert outcome.events[0] == RuleEvent(
        "resource_gathered",
        (7,),
        (("resource", "moonleaf"), ("amount", 1)),
        True,
    )


@pytest.mark.parametrize(
    ("resource", "already", "code"),
    [
        (None, False, "no_resource"),
        ("stone", False, "no_resource"),
        ("moonleaf", True, "already_foraged"),
    ],
)
def test_forage_rejects_unavailable_resources(
    resource: str | None, already: bool, code: str
) -> None:
    with pytest.raises(RuleViolationError, match=code):
        forage(Cultivator(), actor_id=7, resource=resource, already_foraged=already)


@pytest.mark.parametrize("ambient", [-1, True, 1.5, "3"])
def test_cultivate_rejects_invalid_ambient_qi(ambient: object) -> None:
    with pytest.raises(ValueError, match="non-negative integer"):
        cultivate(Cultivator(), actor_id=1, ambient_qi=ambient)


@pytest.mark.parametrize("ambient", [0, 1])
def test_cultivate_rejects_thin_qi(ambient: int) -> None:
    with pytest.raises(RuleViolationError, match="thin_qi"):
        cultivate(Cultivator(), actor_id=1, ambient_qi=ambient)


def test_cultivate_without_herb_gains_one_qi() -> None:
    outcome = cultivate(Cultivator(), actor_id=1, ambient_qi=2)
    assert outcome.state == Cultivator(qi=1)
    assert outcome.events == (
        RuleEvent("qi_refined", (1,), (("amount", 1), ("moonleaf_used", 0)), False),
    )


def test_cultivate_with_herb_can_break_through() -> None:
    outcome = cultivate(Cultivator(qi=1, moonleaf=1), actor_id=9, ambient_qi=3)
    assert outcome.state == Cultivator(
        realm=BREATH_REALM,
        qi=0,
        moonleaf=0,
        insight=1,
        lifespan=88,
    )
    assert [event.kind for event in outcome.events] == ["qi_refined", "realm_advanced"]
    assert outcome.events[-1].permanent is True


def test_cultivate_after_breakthrough_is_bounded() -> None:
    state = Cultivator(realm=BREATH_REALM, qi=2, moonleaf=1, insight=2, lifespan=88)
    with pytest.raises(RuleViolationError, match="realm_complete"):
        cultivate(state, actor_id=9, ambient_qi=0)


def test_prepare_ritual_requires_the_hidden_spring() -> None:
    with pytest.raises(RuleViolationError, match="wrong_ritual_site"):
        prepare_ritual(
            leader_id=3,
            room_id="crossing",
            zone="zhahe-crossing",
            leader=Cultivator(),
        )
    assert prepare_ritual(
        leader_id=3,
        room_id="spring",
        zone="hidden-spring",
        leader=Cultivator(),
    ) == Ritual(3, "spring")


def test_prepare_ritual_is_idempotent_and_cannot_repeat_completed_trial() -> None:
    pending = Ritual(3, "spring")
    with pytest.raises(RuleViolationError, match="ritual_pending"):
        prepare_ritual(
            leader_id=3,
            room_id="spring",
            zone="hidden-spring",
            leader=Cultivator(),
            pending=pending,
        )
    with pytest.raises(RuleViolationError, match="ritual_occupied"):
        prepare_ritual(
            leader_id=4,
            room_id="spring",
            zone="hidden-spring",
            leader=Cultivator(),
            pending=pending,
        )
    with pytest.raises(RuleViolationError, match="trial_complete"):
        prepare_ritual(
            leader_id=3,
            room_id="spring",
            zone="hidden-spring",
            leader=Cultivator(trial_complete=True),
        )


def test_complete_ritual_rejects_self_moved_and_absent_leader() -> None:
    ritual = Ritual(leader_id=3, room_id="spring")
    state = Cultivator()
    with pytest.raises(RuleViolationError, match="self_witness"):
        complete_ritual(
            ritual,
            witness_id=3,
            room_id="spring",
            leader_present=True,
            leader=state,
            witness=state,
        )
    with pytest.raises(RuleViolationError, match="trial_complete"):
        complete_ritual(
            Ritual(3, "spring"),
            witness_id=4,
            room_id="spring",
            leader_present=True,
            leader=Cultivator(trial_complete=True),
            witness=Cultivator(trial_complete=True),
        )
    with pytest.raises(RuleViolationError, match="ritual_moved"):
        complete_ritual(
            ritual,
            witness_id=4,
            room_id="elsewhere",
            leader_present=True,
            leader=state,
            witness=state,
        )
    with pytest.raises(RuleViolationError, match="leader_absent"):
        complete_ritual(
            ritual,
            witness_id=4,
            room_id="spring",
            leader_present=False,
            leader=state,
            witness=state,
        )


def test_complete_ritual_finishes_breath_realm_trial_without_qi_overflow() -> None:
    outcome = complete_ritual(
        Ritual(3, "spring"),
        witness_id=4,
        room_id="spring",
        leader_present=True,
        leader=Cultivator(realm=BREATH_REALM, qi=1, lifespan=88),
        witness=Cultivator(realm=BREATH_REALM, qi=2, lifespan=88),
    )
    assert outcome.leader == Cultivator(
        realm=BREATH_REALM, qi=1, insight=1, lifespan=88, trial_complete=True
    )
    assert outcome.witness == Cultivator(
        realm=BREATH_REALM, qi=2, insight=1, lifespan=88, trial_complete=True
    )
    assert [event.kind for event in outcome.events] == ["formation_completed"]


def test_complete_ritual_can_advance_each_mortal() -> None:
    outcome = complete_ritual(
        Ritual(3, "spring"),
        witness_id=4,
        room_id="spring",
        leader_present=True,
        leader=Cultivator(qi=1),
        witness=Cultivator(qi=2),
    )
    assert outcome.leader == Cultivator(
        realm=BREATH_REALM, insight=2, lifespan=88, trial_complete=True
    )
    assert outcome.witness == Cultivator(
        realm=BREATH_REALM, qi=1, insight=2, lifespan=88, trial_complete=True
    )
    assert [event.kind for event in outcome.events] == [
        "formation_completed",
        "realm_advanced",
        "realm_advanced",
    ]


def test_completed_player_can_mentor_without_repeating_rewards() -> None:
    mentor = Cultivator(
        realm=BREATH_REALM,
        qi=1,
        insight=2,
        lifespan=88,
        trial_complete=True,
    )
    outcome = complete_ritual(
        Ritual(3, "spring"),
        witness_id=4,
        room_id="spring",
        leader_present=True,
        leader=mentor,
        witness=Cultivator(qi=1),
    )
    assert outcome.leader == mentor
    assert outcome.witness == Cultivator(
        realm=BREATH_REALM, insight=2, lifespan=88, trial_complete=True
    )
    assert [event.kind for event in outcome.events] == [
        "formation_completed",
        "realm_advanced",
    ]
    assert dict(outcome.events[0].data) == {
        "leader_qi": 0,
        "witness_qi": 2,
        "leader_insight": 0,
        "witness_insight": 1,
        "room": "spring",
    }
