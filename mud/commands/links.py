"""Server-authored selectable command links for MXP-capable clients."""

from __future__ import annotations


def command_link(command: str, label: str | None = None) -> str:
    """Return an Evennia command link that degrades to its label in text clients."""

    visible_label = label or command
    for value in (command, visible_label):
        if not value or any(character in value for character in "|\r\n"):
            raise ValueError("command links require non-empty, single-line, unstyled text")
    return f"|lc{command}|lt{visible_label}|le"


def command_choices(*commands: str) -> str:
    """Render a compact, consistently separated row of selectable commands."""

    return " · ".join(command_link(command) for command in commands)
