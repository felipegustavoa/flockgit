#!/bin/bash

set -euo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GREEN=$'\e[32m'
RESET=$'\e[0m'

printf "Running CLI tests...\n"
# Exercita o comportamento funcional principal da CLI.
bash "$TESTS_DIR/test_cli.sh"

printf "\nRunning config tests...\n"
# Exercita parsing, validação e regras do arquivo de configuração.
bash "$TESTS_DIR/test_config.sh"

printf "\nRunning git change tests...\n"
# Exercita troca de branch local e remota em cenários Git reais.
bash "$TESTS_DIR/test_git_change.sh"

printf "\nRunning git update tests...\n"
# Exercita update com upstream, sem upstream e com remote renomeado.
bash "$TESTS_DIR/test_git_update.sh"

printf "\nRunning install tests...\n"
# Exercita instalação, reinstalação e desinstalação.
bash "$TESTS_DIR/test_install.sh"

printf "\n%sAll tests passed.%s\n" "$GREEN" "$RESET"
