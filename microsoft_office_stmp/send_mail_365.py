# -*- coding: utf-8 -*-
"""通过 Microsoft 365 (Office 365) SMTP 发送测试邮件到 3173484026@qq.com

用法：python send_mail_365.py
"""

# ===== 在此填写你的账号信息 =====
SMTP_USER = "info@stprosperity.com"   # 发送邮箱（Microsoft 365 账户）
SMTP_PASS = "GJfG672@0f."            # 邮箱密码或应用专用密码（App Password）
# ================================

import smtplib
import sys
from email.header import Header
from email.mime.text import MIMEText
from email.utils import formataddr

SMTP_HOST = "smtp.office365.com"
SMTP_PORT = 587
RECIPIENT = "3173484026@qq.com"

# 邮件正文与标题（中文标题需要编码）
SUBJECT = "Microsoft 365 SMTP 测试邮件"
BODY = (
    "这是一封来自 Microsoft 365 邮箱的 Python SMTP 测试邮件。\n"
    "如果你收到本邮件，说明 SMTP 配置正确，发送成功。\n"
)


def main() -> int:
    sender = SMTP_USER
    password = SMTP_PASS

    if not sender or sender.startswith("你的"):
        print("错误：请先在文件头填写 SMTP_USER 发件邮箱。", file=sys.stderr)
        return 2
    if not password or password.startswith("你的"):
        print("错误：请先在文件头填写 SMTP_PASS 密码/应用专用密码。", file=sys.stderr)
        return 2

    msg = MIMEText(BODY, "plain", "utf-8")
    msg["From"] = formataddr((str(Header("M365 发信测试", "utf-8")), sender))
    msg["To"] = formataddr((str(Header("QQ 收件人", "utf-8")), RECIPIENT))
    msg["Subject"] = Header(SUBJECT, "utf-8")

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=30) as server:
            server.ehlo()
            server.starttls()  # SMTP 365 使用 STARTTLS 加密
            server.ehlo()
            server.login(sender, password)
            server.sendmail(sender, [RECIPIENT], msg.as_string())
        print(f"发送成功：{sender} -> {RECIPIENT}")
        return 0
    except smtplib.SMTPAuthenticationError as e:
        print(f"认证失败（用户名/密码错误，或未启用应用专用密码）：{e}", file=sys.stderr)
        return 1
    except smtplib.SMTPException as e:
        print(f"SMTP 发送失败：{e}", file=sys.stderr)
        return 1
    except OSError as e:
        print(f"网络连接失败：{e}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
