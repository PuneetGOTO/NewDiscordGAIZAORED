import discord
import re
from .abc import MixinMeta
from datetime import timedelta
from redbot.core import commands, i18n
from redbot.core.utils.chat_formatting import humanize_timedelta

_ = i18n.Translator("Mod", __file__)


class Slowmode(MixinMeta):
    """
    Commands regarding channel slowmode management.
    """

    @commands.hybrid_command(name="慢速模式")
    @commands.guild_only()
    @commands.bot_can_manage_channel()
    @commands.admin_or_can_manage_channel()
    async def slowmode(
        self,
        ctx,
        *,
        interval: commands.TimedeltaConverter(
            minimum=timedelta(seconds=0), maximum=timedelta(hours=6), default_unit="seconds"
        ) = timedelta(seconds=0),
    ):
        """更改討論串或文字頻道的慢速模式設定。

        時間間隔可以從 0 秒到 6 小時。
        不帶參數使用此指令將會停用慢速模式。
        """
        seconds = interval.total_seconds()
        await ctx.channel.edit(slowmode_delay=seconds)
        if seconds > 0:
            await ctx.send(
                _("Slowmode interval is now {interval}.").format(
                    interval=humanize_timedelta(timedelta=interval)
                )
            )
        else:
            await ctx.send(_("Slowmode has been disabled."))
