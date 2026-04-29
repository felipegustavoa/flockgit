#!/bin/bash

set -euo pipefail

INSTALL_DIR="${FLOCKGIT_INSTALL_DIR:-$HOME/.flockgit}"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHELL_NAME="$(basename "${SHELL:-}")"

START_MARKER="# >>> flockgit >>>"
END_MARKER="# <<< flockgit <<<"

is_update_install()
{
    # A presença do diretório instalado é suficiente para distinguir update de primeira instalação.
    [[ -d "$INSTALL_DIR" ]]
}

detect_rc_file()
{
    # Prefere o shell atual, mas cai para zsh/bash conhecidos quando necessário.
    case "$SHELL_NAME" in
        zsh) printf "%s\n" "$HOME/.zshrc" ;;
        bash) printf "%s\n" "$HOME/.bashrc" ;;
        *)
            if [[ -f "$HOME/.zshrc" ]]; then
                printf "%s\n" "$HOME/.zshrc"
            else
                printf "%s\n" "$HOME/.bashrc"
            fi
            ;;
    esac
}

copy_runtime_files()
{
    # A instalação é baseada em cópia simples para facilitar update/uninstall.
    mkdir -p "$INSTALL_DIR/modules"

    cp "$SOURCE_DIR/aliases.sh" "$INSTALL_DIR/aliases.sh"
    cp "$SOURCE_DIR/flockgit.sh" "$INSTALL_DIR/flockgit.sh"
    cp "$SOURCE_DIR/check.sh" "$INSTALL_DIR/check.sh"
    cp "$SOURCE_DIR/commands.sh" "$INSTALL_DIR/commands.sh"
    cp "$SOURCE_DIR/functions.sh" "$INSTALL_DIR/functions.sh"
    cp "$SOURCE_DIR/global.sh" "$INSTALL_DIR/global.sh"
    cp "$SOURCE_DIR/LICENSE" "$INSTALL_DIR/LICENSE"
    cp "$SOURCE_DIR/prompt.sh" "$INSTALL_DIR/prompt.sh"
    cp "$SOURCE_DIR/install.sh" "$INSTALL_DIR/install.sh"
    cp "$SOURCE_DIR/uninstall.sh" "$INSTALL_DIR/uninstall.sh"
    cp "$SOURCE_DIR/modules/status.sh" "$INSTALL_DIR/modules/status.sh"
    cp "$SOURCE_DIR/modules/update.sh" "$INSTALL_DIR/modules/update.sh"
    cp "$SOURCE_DIR/modules/change.sh" "$INSTALL_DIR/modules/change.sh"

    chmod +x "$INSTALL_DIR/prompt.sh" "$INSTALL_DIR/install.sh" "$INSTALL_DIR/uninstall.sh"

    # Preenche o config apenas quando ele ainda não existe ou está vazio.
    if [[ ! -s "$INSTALL_DIR/config" ]]; then
        cat > "$INSTALL_DIR/config" <<'EOF'
# Exemplo:
# dir=/Users/felipe/www/pastagit/ base=master
EOF
    fi
}

remove_rc_block()
{
    local rc_file="$1"
    local tmp_file

    [[ -f "$rc_file" ]] || return 0

    # Reescreve o rc file sem o bloco gerenciado atual para evitar drift entre versões.
    tmp_file="$(mktemp)"
    awk -v start="$START_MARKER" -v end="$END_MARKER" '
        $0 == start { skip=1; next }
        $0 == end { skip=0; next }
        !skip { print }
    ' "$rc_file" > "$tmp_file"
    mv "$tmp_file" "$rc_file"
}

ensure_rc_block()
{
    local rc_file="$1"

    touch "$rc_file"

    # Regrava o bloco gerenciado para refletir mudanças no setup instalado.
    remove_rc_block "$rc_file"

    {
        printf "\n%s\n" "$START_MARKER"
        printf "source \"%s/aliases.sh\"\n" "$INSTALL_DIR"
        printf "%s\n" "$END_MARKER"
    } >> "$rc_file"
}

print_summary()
{
    local rc_file="$1"
    local install_mode="$2"
    local show_first_use_hint="$3"

    printf "%s\n" "$install_mode"
    printf "FlockGit instalado em: %s\n" "$INSTALL_DIR"
    printf "shell configurado em: %s\n" "$rc_file"

    if [[ -f "$INSTALL_DIR/config" ]]; then
        printf "config em: %s\n" "$INSTALL_DIR/config"
    fi

    if [[ -f "$INSTALL_DIR/LICENSE" ]]; then
        printf "licenca em: %s\n" "$INSTALL_DIR/LICENSE"
    fi

    if [[ "$show_first_use_hint" == "1" ]]; then
        # O hint de primeiro uso só aparece em instalação nova para não poluir updates.
        printf "\nAntes do primeiro uso, edite o config e adicione seus repositórios.\n"
        printf "Exemplo:\n"
        printf "dir=/path/to/project base=main\n"
        printf "dir=\"/path/with spaces/project\" base=master\n"
    fi

    printf "\nAbra um novo terminal e execute:\n"
    printf "flockgit -h\n"
    printf "\nOu recarregue o shell agora com:\n"
    printf "source \"%s\"\n" "$rc_file"
    printf "flockgit -h\n"
}

case "$(uname -s)" in
    Darwin|Linux) ;;
    *)
        printf "Sistema operacional não suportado por este instalador.\n" >&2
        exit 1
        ;;
esac

RC_FILE="$(detect_rc_file)"
INSTALL_MODE_MESSAGE="Nova instalacao do FlockGit detectada."
SHOW_FIRST_USE_HINT=1

if is_update_install; then
    INSTALL_MODE_MESSAGE="Atualizacao do FlockGit detectada. Os scripts serao atualizados e o config existente sera preservado."
    SHOW_FIRST_USE_HINT=0
fi

copy_runtime_files
ensure_rc_block "$RC_FILE"
print_summary "$RC_FILE" "$INSTALL_MODE_MESSAGE" "$SHOW_FIRST_USE_HINT"
