"""
Command sets

All commands in the game must be grouped in a cmdset.  A given command
can be part of any number of cmdsets and cmdsets can be added/removed
and merged onto entities at runtime.

To create new commands to populate the cmdset, see
`commands/command.py`.

This module wraps the default command sets of Evennia; overloads them
to add/remove commands from the default lineup. You can create your
own cmdsets by inheriting from them or directly from `evennia.CmdSet`.

"""

from evennia import default_cmds
from evennia.commands.default import unloggedin

from commands.chinese import (
    CmdChineseConnect,
    CmdChineseCreate,
    CmdChineseGameHelp,
    CmdChineseLook,
    CmdChineseNoMatch,
    CmdChineseQuit,
    CmdChineseSay,
    CmdChineseUnloggedinHelp,
    CmdChineseUnloggedinLook,
)
from commands.cultivation import (
    CmdCultivate,
    CmdCultivationStatus,
    CmdForage,
    CmdPath,
    CmdPrepareRitual,
    CmdWitness,
)


class CharacterCmdSet(default_cmds.CharacterCmdSet):
    """
    The `CharacterCmdSet` contains general in-game commands like `look`,
    `get`, etc available on in-game Character objects. It is merged with
    the `AccountCmdSet` when an Account puppets a Character.
    """

    key = "DefaultCharacter"

    def at_cmdset_creation(self):
        """
        Populates the cmdset
        """
        super().at_cmdset_creation()
        self.add(CmdChineseLook())
        self.add(CmdChineseSay())
        self.add(CmdChineseGameHelp())
        self.add(CmdChineseNoMatch())
        self.add(CmdCultivationStatus())
        self.add(CmdForage())
        self.add(CmdCultivate())
        self.add(CmdPrepareRitual())
        self.add(CmdWitness())
        self.add(CmdPath())


class AccountCmdSet(default_cmds.AccountCmdSet):
    """
    This is the cmdset available to the Account at all times. It is
    combined with the `CharacterCmdSet` when the Account puppets a
    Character. It holds game-account-specific commands, channel
    commands, etc.
    """

    key = "DefaultAccount"

    def at_cmdset_creation(self):
        """
        Populates the cmdset
        """
        super().at_cmdset_creation()


class UnloggedinCmdSet(default_cmds.UnloggedinCmdSet):
    """
    Command set available to the Session before being logged in.  This
    holds commands like creating a new account, logging in, etc.
    """

    key = "DefaultUnloggedin"

    def at_cmdset_creation(self):
        """Populate the login screen with Chinese-first commands."""

        self.add(CmdChineseConnect())
        self.add(CmdChineseCreate())
        self.add(CmdChineseQuit())
        self.add(CmdChineseUnloggedinLook())
        self.add(CmdChineseUnloggedinHelp())
        self.add(CmdChineseNoMatch())
        self.add(unloggedin.CmdUnconnectedEncoding())
        self.add(unloggedin.CmdUnconnectedScreenreader())
        self.add(unloggedin.CmdUnconnectedInfo())


class SessionCmdSet(default_cmds.SessionCmdSet):
    """
    This cmdset is made available on Session level once logged in. It
    is empty by default.
    """

    key = "DefaultSession"

    def at_cmdset_creation(self):
        """
        This is the only method defined in a cmdset, called during
        its creation. It should populate the set with command instances.

        As and example we just add the empty base `Command` object.
        It prints some info.
        """
        super().at_cmdset_creation()
        #
        # any commands you add below will overload the default ones.
        #
