#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR_DIR="$ROOT_DIR/vendor/tg-ws-proxy-android"
DEST="$ROOT_DIR/src-wrapper"

if [ ! -d "$VENDOR_DIR/.git" ]; then
  echo "Upstream submodule not found at $VENDOR_DIR" >&2
  echo "Run: git submodule update --init" >&2
  exit 1
fi

cd "$VENDOR_DIR"
git fetch origin
UPSTREAM_REF="${UPSTREAM_REF:-main}"
git checkout "$UPSTREAM_REF"
git pull origin "$UPSTREAM_REF"
COMMIT="$(git rev-parse HEAD)"
cd "$ROOT_DIR"

rm -rf "$DEST/src"
mkdir -p "$DEST/src"
cp "$VENDOR_DIR/Cargo.toml" "$DEST/Cargo.toml"
cp "$VENDOR_DIR/Cargo.lock" "$DEST/Cargo.lock"
cp "$VENDOR_DIR/src/"*.rs "$DEST/src/"

git -C "$ROOT_DIR" apply --directory=src-wrapper scripts/patches/ios-ffi.patch

printf '%s\n' "$COMMIT" > "$DEST/UPSTREAM_COMMIT"
printf '%s\n' "https://github.com/amurcanov/tg-ws-proxy-android.git" > "$DEST/UPSTREAM_URL"

echo "Rust wrapper updated to $COMMIT"
