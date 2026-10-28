# VPS 手順書 / VPS runbook(ConoHa VPS、Ubuntu 22.04/24.04 想定)

**未検証**: この手順は一度も実行していない。OSが違う場合(AlmaLinux等)は `apt` を `dnf` に読み替える。コマンドは VPS 上で、SSH接続した状態で実行する。
Unverified: never run end-to-end. Assumes Ubuntu/Debian; adjust package commands otherwise.

## 0. 前提の確認
```bash
cat /etc/os-release | head -2          # OSの確認
nslookup maid-cafe.tokyo               # このVPSのIPが返ること(DNS反映済み)
```

## 1. 鍵認証と管理用ユーザー(ロックアウト防止のため、**別の端末でも接続できるのを確認してから**パスワード認証を切る)
```bash
adduser --disabled-password --gecos "" admin && usermod -aG sudo admin
mkdir -p /home/admin/.ssh && cp ~/.ssh/authorized_keys /home/admin/.ssh/ && chown -R admin:admin /home/admin/.ssh && chmod 700 /home/admin/.ssh
# 別ターミナルで ssh admin@<VPSのIP> が通ることを確認してから:
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/; s/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl reload ssh
```

## 2. ファイアウォール(22/80/443 のみ)
```bash
apt update && apt install -y ufw curl
ufw allow 22/tcp && ufw allow 80/tcp && ufw allow 443/tcp && ufw --force enable
```
ConoHa のコントロールパネル側のセキュリティグループでも、22/80/443 を許可しているか確認する(私は操作できない)。

## 3. サービス用ユーザーとディレクトリ
```bash
useradd --system --home /srv/maid-cafe --shell /usr/sbin/nologin maid
mkdir -p /srv/maid-cafe/releases /etc/maid-cafe /var/lib/maid-cafe/data
chown -R maid:maid /var/lib/maid-cafe
```

## 4. Caddy の導入(HTTPSは自動取得)
```bash
apt install -y debian-keyring debian-archive-keyring apt-transport-https gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy
```
手元の `deploy/Caddyfile` を `/etc/caddy/Caddyfile` に置く(scp 等)。**バックエンドが未起動でも Caddy は起動できる**(その間は502)。
```bash
caddy validate --config /etc/caddy/Caddyfile && systemctl reload caddy
journalctl -u caddy -n 30 --no-pager     # 証明書取得の成功/失敗を確認
```

## 5. 設定ファイル(秘密。権限600、リポジトリに入れない)
```bash
install -m 600 -o root -g root /dev/null /etc/maid-cafe/english.env
install -m 600 -o root -g root /dev/null /etc/maid-cafe/data.env
```
中身は最初は空でよい。必要な項目(SMTPのパスワード等)は、機能を有効にするときに足す。
**公開前の確認(必須)**: open-english-server には VPS/GitHub を操作するエージェント系のAPIがある。公開してよい状態か、認証が必須か、`server/src/vps_agent.rs` `github_agent.rs` `local_agent.rs` を読んで確認するまで、`/etc/maid-cafe/english.env` に鍵やトークンを**入れない**。

## 6. unit と更新スクリプト
```bash
# 手元から: deploy/systemd/*  → /etc/systemd/system/ 、 deploy/bin/update.sh → /srv/maid-cafe/update.sh
chmod 755 /srv/maid-cafe/update.sh
systemctl daemon-reload
```

## 7. 初回の成果物を入れる(どちらか)
**A. リリースから(推奨・CIでビルドした後)**: リリースに `maid-cafe-tokyo-linux-x86_64.tar.gz` と `SHA256SUMS` が付いていること。
```bash
/srv/maid-cafe/update.sh               # root で実行。展開→切替→起動→ヘルスチェック(失敗なら自動で戻す)
```
tar.gz の中身は `bin/open-english-server`、`bin/rrd-server`、`open-english/web/` を想定(CIで作る)。
**B. VPSでビルド(CIができるまでの代替)**: `deps.lock` のコミットを兄弟として取得してビルドする。時間とメモリが要る(2GB未満だとビルドが落ちやすい)。open-english は `open-english/server` から `../../RPoem` を参照するので、`open-english` と `RPoem` 等を同じ親ディレクトリに置く。realdata.pro は `scripts/fetch-deps.sh` を使う。**この手順は未検証。**

## 8. 有効化と確認
```bash
systemctl enable --now maid-english maid-data maid-update.timer
systemctl status maid-english maid-data --no-pager
curl -fsS http://127.0.0.1:4601/healthz ; curl -fsS http://127.0.0.1:4701/healthz
curl -I https://maid-cafe.tokyo/       # 200 とHTTPSの証明書
systemctl list-timers | grep maid-update
```
ブラウザで `https://maid-cafe.tokyo/` と `https://maid-cafe.tokyo/data/` を開いて、実際に表示されることを確認する。

## 9. 自動ロールバックの確認(必ず一度試す)
わざとヘルスチェックが失敗する版(壊れたバイナリ)をリリースに載せ、`/srv/maid-cafe/update.sh` を実行して、前の版へ戻って `current` が元に戻ることを確認する。試していない間は「自動ロールバックは未確認」。

## 10. うまくいかないとき
- 証明書が取れない: DNSが VPS のIPか(`nslookup`)、80/443 が外から届くか(ConoHaのセキュリティグループ)、`journalctl -u caddy`。
- 502: `systemctl status maid-english`、`journalctl -u maid-english -n 50`。
- ログイン不能になった: ConoHa のコンソール(VNC)から入る。
