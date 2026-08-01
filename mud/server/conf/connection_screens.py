"""《山河有契》中文登录欢迎页。"""

from django.conf import settings
from evennia import utils

CONNECTION_SCREEN = """
|g==============================================================|n
                         |w山 河 有 契|n
                  一方持续生长的多人修仙世界

  已有账号：|w登录 <账号名> <密码>|n
  创建账号：|w注册 <账号名> <密码>|n

  输入 |w帮助|n 查看说明，输入 |w查看|n 重看本页。
  游戏：{} · 引擎版本：{}
|g==============================================================|n""".format(
    settings.SERVERNAME, utils.get_evennia_version("short")
)
