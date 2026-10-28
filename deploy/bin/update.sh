#!/usr/bin/env bash
# 新しい版(CIがgreenのリリース)があれば取り込み、ヘルスチェックに失敗したら前の版へ戻す。
# 取得元は $REPO のGitHub Releases(成果物 maid-cafe-tokyo-linux-x86_64.tar.gz と SHA256SUMS)。
set -euo pipefail
ROOT=/srv/maid-cafe; REPO=${REPO:-aon-co-jp/maid-cafe-tokyo}
cd "$ROOT"
tag=$(curl -fsS "https://api.github.com/repos/$REPO/releases/latest" | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -1)
[ -n "$tag" ] || { echo "最新版が分かりません"; exit 1; }
cur=$(basename "$(readlink -f current 2>/dev/null)" 2>/dev/null || true)
[ "$tag" = "$cur" ] && { echo "最新です: $cur"; exit 0; }
mkdir -p "releases/$tag" && cd "releases/$tag"
base="https://github.com/$REPO/releases/download/$tag"
curl -fsSLO "$base/maid-cafe-tokyo-linux-x86_64.tar.gz"
curl -fsSLO "$base/SHA256SUMS"
sha256sum -c --ignore-missing SHA256SUMS
tar xzf maid-cafe-tokyo-linux-x86_64.tar.gz && rm maid-cafe-tokyo-linux-x86_64.tar.gz
cd "$ROOT"
prev=$(readlink -f current 2>/dev/null || true)
ln -sfn "releases/$tag" current.new && mv -T current.new current
sudo systemctl restart maid-english maid-data
sleep 5
if curl -fsS http://127.0.0.1:4601/healthz >/dev/null && curl -fsS http://127.0.0.1:4701/healthz >/dev/null; then
  echo "更新しました: $tag"
  ls -1dt releases/* | tail -n +4 | xargs -r rm -rf   # 新しい3つを残す
else
  echo "ヘルスチェック失敗。戻します: $prev" >&2
  [ -n "$prev" ] && ln -sfn "$prev" current.new && mv -T current.new current && sudo systemctl restart maid-english maid-data
  exit 1
fi
