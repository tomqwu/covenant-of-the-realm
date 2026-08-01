"""Player-facing Chinese localization tests."""

from commands.chinese import (
    CmdChineseGameHelp,
    CmdChineseSay,
    CmdChineseUnloggedinHelp,
    CmdChineseUnloggedinLook,
    _split_credentials,
)
from commands.cultivation import (
    CmdCultivate,
    CmdCultivationStatus,
    CmdForage,
    CmdPath,
    CmdPrepareRitual,
    CmdWitness,
)
from commands.links import command_choices, command_link
from evennia.utils.ansi import strip_mxp
from evennia.utils.test_resources import EvenniaCommandTest
from server.conf.connection_screens import CONNECTION_SCREEN


class ChineseExperienceTests(EvenniaCommandTest):
    def test_connection_screen_is_chinese_first(self):
        self.assertIn("山 河 有 契", CONNECTION_SCREEN)
        self.assertIn("登录 <账号名> <密码>", CONNECTION_SCREEN)
        self.assertIn("注册 <账号名> <密码>", CONNECTION_SCREEN)
        self.assertNotIn("Welcome", CONNECTION_SCREEN)

    def test_credentials_support_plain_and_quoted_values(self):
        self.assertEqual(_split_credentials("青石客 长密码"), ["青石客", "长密码"])
        self.assertEqual(
            _split_credentials('"青 石 客" "带 空 格 的 密 码"'),
            ["青 石 客", "带 空 格 的 密 码"],
        )

    def test_player_help_and_speech_use_chinese(self):
        self.call(CmdChineseGameHelp(), "", "《山河有契》常用命令")
        self.call(CmdChineseSay(), "", "你想说什么？")
        self.call(CmdChineseSay(), "山河同道", "你说道：“山河同道”")

    def test_command_links_are_selectable_and_have_text_fallbacks(self):
        link = command_link("修炼", "开始修炼")
        self.assertEqual(link, "|lc修炼|lt开始修炼|le")
        self.assertEqual(strip_mxp(link), "开始修炼")
        self.assertEqual(strip_mxp(command_choices("布阵", "见证")), "布阵 · 见证")
        for unsafe_value in ("", "修炼|n", "修炼\n见证"):
            with self.subTest(value=unsafe_value), self.assertRaises(ValueError):
                command_link(unsafe_value)

    def test_room_footer_offers_contextual_selectable_actions(self):
        self.room1.db.zone_id = "moonleaf-terrace"
        terrace_footer = self.room1.get_display_footer(self.char1)
        self.assertIn("|lc采药|lt采药|le", terrace_footer)
        self.assertIn("|lc修为|lt修为|le", terrace_footer)

        self.room1.db.zone_id = "hidden-spring"
        self.room1.db.pending_ritual = {"leader_id": self.char2.id}
        spring_footer = self.room1.get_display_footer(self.char1)
        self.assertIn("|lc修炼|lt修炼|le", spring_footer)
        self.assertIn("|lc见证|lt见证|le", spring_footer)
        self.assertNotIn("|lc布阵|lt布阵|le", spring_footer)

    def test_login_help_is_chinese(self):
        self.call(CmdChineseUnloggedinHelp(), "", "登录前可用命令")
        self.assertIn("查看", CmdChineseUnloggedinLook.aliases)

    def test_gameplay_commands_are_chinese_first_with_english_compatibility(self):
        commands = (
            (CmdCultivationStatus, "修为", "status"),
            (CmdForage, "采药", "forage"),
            (CmdCultivate, "修炼", "cultivate"),
            (CmdPrepareRitual, "布阵", "prepare"),
            (CmdWitness, "见证", "witness"),
            (CmdPath, "指引", "path"),
        )
        for command_type, chinese_key, english_alias in commands:
            with self.subTest(command=command_type.__name__):
                self.assertEqual(command_type.key, chinese_key)
                self.assertIn(english_alias, command_type.aliases)
