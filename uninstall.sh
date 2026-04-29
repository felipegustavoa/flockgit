#!/bin/bash

set -euo pipefail

INSTALL_DIR="${FLOCKGIT_INSTALL_DIR:-$HOME/.flockgit}"
START_MARKER="# >>> flockgit >>>"
END_MARKER="# <<< flockgit <<<"

remove_rc_block()
{
    local rc_file="$1"
    local start_marker="$2"
    local end_marker="$3"
    local tmp_file

    [[ -f "$rc_file" ]] || return 0

    # Remove apenas o bloco delimitado pelo instalador, preservando o resto do rc file.
    tmp_file="$(mktemp)"
    awk -v start="$start_marker" -v end="$end_marker" '
        $0 == start { skip=1; next }
        $0 == end { skip=0; next }
        !skip { print }
    ' "$rc_file" > "$tmp_file"
    mv "$tmp_file" "$rc_file"
}

remove_rc_block "$HOME/.zshrc" "$START_MARKER" "$END_MARKER"
remove_rc_block "$HOME/.bashrc" "$START_MARKER" "$END_MARKER"

if [[ -d "$INSTALL_DIR" ]]; then
    # A pasta instalada é inteiramente gerenciada pelo projeto.
    rm -rf "$INSTALL_DIR"
fi

printf "FlockGit removido de: %s\n" "$INSTALL_DIR"
printf "Abra um novo terminal para refletir a remoção.\n"
