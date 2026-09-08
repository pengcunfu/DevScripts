# -*- coding: utf-8 -*-
"""一键开启 Microsoft 365 的 SMTP AUTH（租户级 + 邮箱级）并验证。

用法：
    python enable_smtp_auth.py

运行后会打印一个网址 + 代码：用浏览器打开网址、输入代码、以管理员邮箱登录，
脚本自动完成后续所有操作：
    获取令牌 -> 连接 Exchange Online -> 开启租户级 SMTP AUTH
    -> 开启邮箱级 SMTP AUTH -> 验证并输出结果。

（幂等：已开启时重复运行也会安全地把值再设为开启。）
"""

import codecs
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

# ===== 可修改配置 =====
TENANT = "stprosperity.com"
MAILBOX = "info@stprosperity.com"
# ======================

CLIENT_ID = "fb78d390-0c51-40cd-8e17-fdbfab77341b"  # Exchange Online PowerShell app ID
SCOPE = "https://outlook.office365.com/.default"


def post(url, data):
    body = urllib.parse.urlencode(data).encode()
    req = urllib.request.Request(
        url, data=body, headers={"Content-Type": "application/x-www-form-urlencoded"}
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.loads(resp.read().decode())


def get_token():
    dc = post(
        "https://login.microsoftonline.com/%s/oauth2/v2.0/devicecode" % TENANT,
        {"client_id": CLIENT_ID, "scope": SCOPE},
    )
    print("=" * 62)
    print("  请打开网址: %s" % dc["verification_uri"])
    print("  请输入代码: %s" % dc["user_code"])
    print("  用账号登录: %s" % MAILBOX)
    print("=" * 62)
    sys.stdout.flush()

    interval = int(dc["interval"])
    token_url = "https://login.microsoftonline.com/%s/oauth2/v2.0/token" % TENANT
    while True:
        time.sleep(interval)
        try:
            tok = post(
                token_url,
                {
                    "grant_type": "urn:ietf:params:oauth:grant-type:device_code",
                    "client_id": CLIENT_ID,
                    "device_code": dc["device_code"],
                },
            )
            return tok["access_token"]
        except urllib.error.HTTPError as e:
            body = e.read().decode()
            try:
                err = json.loads(body).get("error", "")
            except Exception:
                err = body
            if err == "authorization_pending":
                continue
            if err == "slow_down":
                interval += 5
                continue
            print("登录失败: %s | %s" % (err, body))
            sys.exit(1)
        except Exception as e:
            print("网络错误: %s" % e)
            sys.exit(1)


def run_enable(token_path):
    ps = (
        "[Console]::OutputEncoding = [System.Text.Encoding]::UTF8\n"
        "$ErrorActionPreference = 'Stop'\n"
        "$token = (Get-Content '%TOKEN%' -Raw).Trim()\n"
        "Import-Module ExchangeOnlineManagement -ErrorAction Stop\n"
        "Write-Output '== 连接 Exchange Online =='\n"
        "Connect-ExchangeOnline -AccessToken $token -UserPrincipalName '%MAILBOX%'\n"
        "Write-Output '== 开启租户级 SMTP AUTH =='\n"
        "Set-TransportConfig -SmtpClientAuthenticationDisabled $false\n"
        "Write-Output '== 开启邮箱级 SMTP AUTH =='\n"
        "Set-CASMailbox -Identity '%MAILBOX%' -SmtpClientAuthenticationDisabled $false\n"
        "Write-Output '== 验证结果 =='\n"
        "Get-TransportConfig | Format-List SmtpClientAuthenticationDisabled\n"
        "Get-CASMailbox -Identity '%MAILBOX%' | Format-List PrimarySmtpAddress, SmtpClientAuthenticationDisabled\n"
        "Disconnect-ExchangeOnline -Confirm:$false -ErrorAction SilentlyContinue\n"
        "Write-Output '== DONE =='\n"
    ).replace("%TOKEN%", token_path.replace("\\", "/")).replace("%MAILBOX%", MAILBOX)

    ps_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "_enable_tmp.ps1")
    # 写 UTF-8 BOM，避免 Windows PowerShell 5.1 按 ANSI 读取导致中文乱码
    with open(ps_file, "wb") as f:
        f.write(codecs.BOM_UTF8 + ps.encode("utf-8"))
    try:
        r = subprocess.run(
            ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", ps_file],
            capture_output=True,
        )
        sys.stdout.buffer.write(r.stdout)
        sys.stderr.buffer.write(r.stderr)
        sys.stdout.buffer.flush()
        return r.returncode == 0
    finally:
        if os.path.exists(ps_file):
            os.remove(ps_file)


def main():
    token = get_token()
    token_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "exo_token_tmp.txt")
    with open(token_path, "w", encoding="ascii") as f:
        f.write(token)
    try:
        ok = run_enable(token_path)
        print("结果：SMTP AUTH 开启%s" % ("成功" if ok else "失败（请查看上方输出）"))
    finally:
        if os.path.exists(token_path):
            os.remove(token_path)


if __name__ == "__main__":
    main()
