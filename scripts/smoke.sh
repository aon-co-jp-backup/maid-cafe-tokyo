#!/usr/bin/env bash
# 成果物を展開して2つのサーバーを実際に起動し、/healthz が応答することを確認する。
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"; t="$(mktemp -d)"; tar -C "$t" -xzf "$here/dist/maid-cafe-tokyo-linux-x86_64.tar.gz"
cd "$t"
OPEN_ENGLISH_SERVER_BIND=127.0.0.1:4601 OPEN_ENGLISH_SERVER_ROOT="$t/open-english/web" ./bin/open-english-server >"$t/e.log" 2>&1 &
RRD_BIND=127.0.0.1:4701 RRD_DATA_DIR="$t/data" ./bin/rrd-server >"$t/d.log" 2>&1 &
ok=0
for i in $(seq 1 60); do
  if curl -fsS http://127.0.0.1:4601/healthz >/dev/null 2>&1 && curl -fsS http://127.0.0.1:4701/healthz >/dev/null 2>&1; then ok=1; break; fi; sleep 2
done
curl -fsS http://127.0.0.1:4601/ | head -c 200 || true
kill %1 %2 2>/dev/null || true
[ "$ok" = 1 ] || { echo "ヘルスチェック失敗"; tail -30 "$t/e.log" "$t/d.log"; exit 1; }
echo "スモークテスト合格"
