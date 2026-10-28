# maid-cafe.tokyo

メイドカフェ先生の英会話・学習(maid-cafe-english)と、データ分析(realdata.pro)のハイブリッド。設計の正本は `maid-cafe-se` リポジトリの `docs/maid-cafe-tokyo-design.md`。
Hybrid of the maid-cafe English teacher (maid-cafe-english) and data analysis (realdata.pro). Design doc: `docs/maid-cafe-tokyo-design.md` in `maid-cafe-se`.

## 構成 / Layout
```
利用者 → Caddy(HTTPS 443) ─┬─ /data/*  → rrd-server        127.0.0.1:4701 (realdata.pro)
                           └─ それ以外 → open-english-server 127.0.0.1:4601 (maid-cafe-english)
```
- `deploy/Caddyfile` / `deploy/systemd/*` / `deploy/bin/update.sh`: 配備と毎朝05:00(JST)の自動更新(失敗時は自動ロールバック)。秘密情報は含まない。
- `deps.lock`: 依存リポジトリのコミット固定(2026-10-28時点の各master最新)。
- 秘密(`/etc/maid-cafe/*.env`)はVPS上にだけ置き、リポジトリに入れない。

## 状態 / Status(正直に)
- **未配備・未検証**。VPSでの実行、HTTPS取得、自動更新とロールバックは一度も実行していない。
- RPoem最新コミットのCIは failure(保守中)。固定したコミットでのビルド成功は未確認。
- open-english-server には VPS/GitHub 操作のエージェント機能があり、**公開前に無効化または認証必須か確認が必要**。
- Not deployed, not verified. RPoem master CI is failing (under maintenance). Review the server's VPS/GitHub agent endpoints before exposing it publicly.

## 次の手順 / Next
1. CIで両サーバーをビルドして成果物 `maid-cafe-tokyo-linux-x86_64.tar.gz` と `SHA256SUMS` をリリースに添付。
2. VPSに `maid` ユーザー・Caddy・systemd unit を入れ、初回の `update.sh` を手動実行。
3. `https://maid-cafe.tokyo/` と `/data/` の表示を実機で確認。
