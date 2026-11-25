#!/usr/bin/env bash
# Installs gamebox to ~/.local/bin (or $PREFIX/bin).
set -euo pipefail
dest="${PREFIX:-$HOME/.local}/bin"
mkdir -p "$dest"
install -m 755 "$(dirname "$0")/gamebox" "$dest/gamebox"
echo "Installed to $dest/gamebox"
for dep in bwrap wine winetricks; do
  command -v "$dep" >/dev/null || echo "Missing dependency: $dep  (Arch: sudo pacman -S ${dep/bwrap/bubblewrap})"
done
case ":$PATH:" in *":$dest:"*) ;; *) echo "Note: $dest is not on your PATH";; esac
