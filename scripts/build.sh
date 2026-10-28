#!/usr/bin/env bash
# deps.lock のコミットを W 配下に兄弟として取得し、2つのサーバーをビルドして dist/ に成果物を作る。
# 配置: W/<依存...>  W/open-english(=maid-cafe-english)  W/realdata.pro(.deps -> W)
set -euo pipefail
here="$(cd "$(dirname "$0")/.." && pwd)"; W="${W:-$here/work}"; mkdir -p "$W"
grep -vE '^\s*(#|$)' "$here/deps.lock" | while read -r name url rev; do
  d="$W/$name"; [ "$name" = maid-cafe-english ] && d="$W/open-english"
  [ -d "$d/.git" ] || git clone --quiet --filter=blob:none --no-checkout "$url" "$d"
  git -C "$d" fetch --quiet origin "$rev" 2>/dev/null || git -C "$d" fetch --quiet origin
  git -C "$d" -c advice.detachedHead=false checkout --quiet "$rev"
done
ln -sfn "$W" "$W/realdata.pro/.deps"
cargo build --release --manifest-path "$W/open-english/server/Cargo.toml"
cargo build --release --manifest-path "$W/realdata.pro/Cargo.toml" -p rrd-server
out="$here/dist/pkg"; rm -rf "$here/dist"; mkdir -p "$out/bin" "$out/open-english"
cp "$W/open-english/server/target/release/open-english-server" "$out/bin/"
cp "$W/realdata.pro/target/release/rrd-server" "$out/bin/"
cp -r "$W/open-english/web" "$out/open-english/web"
git -C "$here" rev-parse HEAD > "$out/REVISION"; cp "$here/deps.lock" "$out/deps.lock"
tar -C "$out" -czf "$here/dist/maid-cafe-tokyo-linux-x86_64.tar.gz" .
(cd "$here/dist" && sha256sum maid-cafe-tokyo-linux-x86_64.tar.gz > SHA256SUMS)
echo built; ls -l "$here/dist"
