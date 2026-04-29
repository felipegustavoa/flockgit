#!/bin/bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$TESTS_DIR/helpers.sh"

test_install_and_reinstall()
{
    local app_dir home_dir install_dir first_output second_output

    # Instalação precisa ser idempotente e preservar o config do usuário.
    app_dir="$(make_temp_app)"
    home_dir="$(mktemp -d)"
    install_dir="$home_dir/.flockgit"

    first_output="$(HOME="$home_dir" SHELL=/bin/zsh FLOCKGIT_INSTALL_DIR="$install_dir" bash "$app_dir/install.sh")"
    assert_file_contains "$home_dir/.zshrc" "# >>> flockgit >>>" "install should append the managed block"
    assert_file_contains "$home_dir/.zshrc" "source \"$install_dir/aliases.sh\"" "install should source aliases.sh"
    assert_contains "$first_output" "Nova instalacao do FlockGit detectada." "first install should announce a new installation"
    assert_file_contains "$install_dir/config" "# Exemplo:" "first install should create a commented config example"
    assert_file_contains "$install_dir/config" "# dir=/Users/felipe/www/pastagit/ base=master" "first install should include a sample repository line"
    assert_file_contains "$install_dir/LICENSE" "GNU GENERAL PUBLIC LICENSE" "install should copy the license file"
    assert_contains "$first_output" "licenca em: $install_dir/LICENSE" "first install should show where the license was installed"

    printf "dir=/custom/repo base=main\n" > "$install_dir/config"
    python3 - <<PY
from pathlib import Path
rc_file = Path("$home_dir/.zshrc")
content = rc_file.read_text()
content = content.replace('source "$install_dir/aliases.sh"', 'source "$install_dir/flockgit.sh"')
rc_file.write_text(content)
PY
    second_output="$(HOME="$home_dir" SHELL=/bin/zsh FLOCKGIT_INSTALL_DIR="$install_dir" bash "$app_dir/install.sh")"

    assert_file_contains "$install_dir/config" "dir=/custom/repo base=main" "reinstall should preserve config"
    assert_file_contains "$install_dir/LICENSE" "GNU GENERAL PUBLIC LICENSE" "reinstall should keep the license file installed"
    assert_eq "1" "$(grep -c '^# >>> flockgit >>>$' "$home_dir/.zshrc")" "reinstall should not duplicate the rc block"
    assert_file_contains "$home_dir/.zshrc" "source \"$install_dir/aliases.sh\"" "reinstall should refresh the managed source line"
    assert_contains "$second_output" "Atualizacao do FlockGit detectada." "reinstall should announce update mode"
    assert_contains "$second_output" "licenca em: $install_dir/LICENSE" "reinstall should show where the license is installed"
    print_pass "install and reinstall"
}

test_empty_config_is_seeded_on_reinstall()
{
    local app_dir home_dir install_dir

    # Se o config existir mas estiver vazio, a reinstalação deve reidratar o exemplo comentado.
    app_dir="$(make_temp_app)"
    home_dir="$(mktemp -d)"
    install_dir="$home_dir/.flockgit"

    HOME="$home_dir" SHELL=/bin/zsh FLOCKGIT_INSTALL_DIR="$install_dir" bash "$app_dir/install.sh" >/dev/null
    : > "$install_dir/config"
    HOME="$home_dir" SHELL=/bin/zsh FLOCKGIT_INSTALL_DIR="$install_dir" bash "$app_dir/install.sh" >/dev/null

    assert_file_contains "$install_dir/config" "# Exemplo:" "reinstall should seed an empty config file"
    assert_file_contains "$install_dir/config" "# dir=/Users/felipe/www/pastagit/ base=master" "reinstall should restore the sample config line"
    print_pass "empty config seeded on reinstall"
}

test_uninstall()
{
    local app_dir home_dir install_dir

    # Desinstalação deve remover os arquivos instalados e limpar o bloco do shell rc.
    app_dir="$(make_temp_app)"
    home_dir="$(mktemp -d)"
    install_dir="$home_dir/.flockgit"

    HOME="$home_dir" SHELL=/bin/bash FLOCKGIT_INSTALL_DIR="$install_dir" bash "$app_dir/install.sh" >/dev/null
    HOME="$home_dir" FLOCKGIT_INSTALL_DIR="$install_dir" bash "$install_dir/uninstall.sh" >/dev/null

    [[ ! -d "$install_dir" ]] || fail "uninstall should remove the installation directory"
    if [[ -f "$home_dir/.bashrc" ]]; then
        ! grep -Fq "# >>> flockgit >>>" "$home_dir/.bashrc" || fail "uninstall should remove the managed rc block"
    fi
    print_pass "uninstall"
}

# Executa a suíte de instalação separadamente da suíte de CLI.
test_install_and_reinstall
test_empty_config_is_seeded_on_reinstall
test_uninstall
