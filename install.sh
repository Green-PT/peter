#!/usr/bin/env bash
# Sync the tracked /build skill and its agents with ~/.claude.
#
#   ./install.sh            repo -> ~/.claude   (default)
#   ./install.sh pull       ~/.claude -> repo
#   ./install.sh check      diff both ways, non-zero on drift
#
# ~/.claude is not version-controlled; this repo is the tracked copy.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_HOME:-$HOME/.claude}"

case "${1:-install}" in
install)
	mkdir -p "$dest/skills" "$dest/agents"
	rm -rf "${dest:?}/skills/build"
	cp -R "$repo/skills/build" "$dest/skills/build"
	cp "$repo"/agents/*.md "$dest/agents/"
	echo "installed -> $dest"
	;;
pull)
	rm -rf "${repo:?}/skills/build"
	cp -R "$dest/skills/build" "$repo/skills/build"
	cp "$dest"/agents/{backend-builder,frontend-builder,security-auditor,ui-auditor}.md "$repo/agents/"
	echo "pulled <- $dest"
	;;
check)
	diff -r "$repo/skills/build" "$dest/skills/build"
	for f in "$repo"/agents/*.md; do
		diff "$f" "$dest/agents/$(basename "$f")"
	done
	echo "in sync"
	;;
*)
	echo "usage: ${0##*/} [install|pull|check]" >&2
	exit 2
	;;
esac
