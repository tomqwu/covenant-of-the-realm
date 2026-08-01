"""中文登录、查看、交流与帮助命令。"""

from __future__ import annotations

import re
from typing import ClassVar

from django.conf import settings
from evennia import syscmdkeys
from evennia.commands.default import unloggedin
from evennia.utils import class_from_module

from commands.command import Command


def _split_credentials(arguments: str) -> list[str]:
    parts = [part.strip() for part in re.split(r'"', arguments) if part.strip()]
    return parts[0].split(None, 1) if len(parts) == 1 else parts


class CmdChineseConnect(unloggedin.CmdUnconnectedConnect):
    """登录已有账号。用法：登录 <账号名> <密码>"""

    key = "登录"
    aliases: ClassVar[list[str]] = ["连接", "connect", "conn", "con", "co"]

    def func(self) -> None:
        session = self.caller
        parts = _split_credentials(self.args)
        if len(parts) != 2:
            session.msg("用法：登录 <账号名> <密码>")
            return

        account_typeclass = class_from_module(settings.BASE_ACCOUNT_TYPECLASS)
        account, _errors = account_typeclass.authenticate(
            username=parts[0],
            password=parts[1],
            ip=session.address,
            session=session,
        )
        if account:
            session.sessionhandler.login(session, account)
        else:
            session.msg("|R账号名或密码不正确，请稍后再试。|n")


class CmdChineseCreate(unloggedin.CmdUnconnectedCreate):
    """注册新账号。用法：注册 <账号名> <密码>"""

    key = "注册"
    aliases: ClassVar[list[str]] = ["创建账号", "create", "cre", "cr"]

    def at_pre_cmd(self):
        if not settings.NEW_ACCOUNT_REGISTRATION_ENABLED:
            self.msg("当前暂不开放新账号注册。")
            return True
        return super().at_pre_cmd()

    def func(self):
        session = self.caller
        parts = _split_credentials(self.args.strip())
        if len(parts) != 2:
            session.msg(
                "用法：注册 <账号名> <密码>\n"
                "账号名或密码含空格时，请使用英文双引号括起。"
            )
            return

        account_typeclass = class_from_module(settings.BASE_ACCOUNT_TYPECLASS)
        username, password = parts
        normalized = account_typeclass.normalize_username(username)
        if normalized != username:
            session.msg(f"账号名已规范化为：{normalized}")
        username = normalized

        answer = yield f"确认创建账号『{username}』？[是]/否"
        if answer.strip().lower() in {"否", "不", "n", "no"}:
            session.msg("已取消注册。")
            return

        account, _errors = account_typeclass.create(
            username=username,
            password=password,
            ip=session.address,
            session=session,
        )
        if account:
            session.msg(f"新账号『{username}』创建成功。请使用：登录 {username} <密码>")
        else:
            session.msg("|R账号创建失败。请检查账号名与密码要求，稍后再试。|n")


class CmdChineseQuit(unloggedin.CmdUnconnectedQuit):
    """退出连接。用法：退出"""

    key = "退出"
    aliases: ClassVar[list[str]] = ["离开", "quit", "q", "qu"]

    def func(self) -> None:
        self.caller.sessionhandler.disconnect(self.caller, "已退出《山河有契》。")


class CmdChineseUnloggedinHelp(unloggedin.CmdUnconnectedHelp):
    """查看登录帮助。"""

    key = "帮助"
    aliases: ClassVar[list[str]] = ["help", "h", "?"]

    def func(self) -> None:
        self.caller.msg(
            "|w登录前可用命令|n\n"
            "  |w注册 <账号名> <密码>|n —— 创建账号\n"
            "  |w登录 <账号名> <密码>|n —— 进入游戏\n"
            "  |w查看|n —— 重看欢迎页\n"
            "  |w帮助|n —— 显示本说明\n"
            "  |w退出|n —— 断开连接\n\n"
            "示例：|w注册 青石客 一段足够长的密码|n"
        )


class CmdChineseUnloggedinLook(unloggedin.CmdUnconnectedLook):
    """重新显示中文欢迎页。"""

    aliases: ClassVar[list[str]] = ["查看", "看", "look", "l"]


class CmdChineseLook(Command):
    """查看当前地点或附近目标。用法：查看 [目标]"""

    key = "look"
    aliases: ClassVar[list[str]] = ["查看", "看", "l", "ls"]
    locks = "cmd:all()"
    arg_regex = r"\s|$"
    help_category = "常用"

    def func(self) -> None:
        caller = self.caller
        if self.args:
            matches = caller.search(self.args, quiet=True)
            if not matches:
                caller.msg(f"附近没有找到『{self.args}』。")
                return
            if len(matches) > 1:
                caller.msg(f"『{self.args}』指向多个目标，请说得更具体一些。")
                return
            target = matches[0]
        else:
            target = caller.location
        if not target:
            caller.msg("你目前不在任何地点。")
            return
        self.msg(text=(caller.at_look(target), {"type": "look"}), options=None)


class CmdChineseSay(Command):
    """与同一地点的玩家说话。用法：说 <内容>"""

    key = "say"
    aliases: ClassVar[list[str]] = ["说", "交谈", '"', "'"]
    locks = "cmd:all()"
    arg_regex = None
    help_category = "常用"

    def func(self) -> None:
        if not self.args:
            self.caller.msg("你想说什么？")
            return
        speech = self.caller.at_pre_say(self.args)
        if speech:
            self.caller.at_say(
                speech,
                msg_self="你说道：“{speech}”",
                msg_location="{object}说道：“{speech}”",
            )


class CmdChineseGameHelp(Command):
    """查看中文游戏指引。用法：帮助"""

    key = "help"
    aliases: ClassVar[list[str]] = ["帮助", "指令", "h", "?"]
    locks = "cmd:all()"
    help_category = "常用"

    def func(self) -> None:
        self.caller.msg(
            "|w《山河有契》常用命令|n\n"
            "  查看 —— 查看当前地点\n"
            "  东／西／南／北 —— 移动\n"
            "  说 <内容> —— 与同场玩家交谈\n"
            "  指引 —— 查看当前修行路线\n"
            "  修为 —— 查看境界与资源\n"
            "  采药／修炼／布阵／见证 —— 执行修行行动"
        )


class CmdChineseNoMatch(Command):
    """以中文处理无法识别的输入。"""

    key = syscmdkeys.CMD_NOMATCH
    locks = "cmd:all()"

    def func(self) -> None:
        self.caller.msg(f"无法识别指令『{self.args}』。输入『帮助』查看可用命令。")
