#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# O entrypoint carrega os módulos uma vez e depois só roteia comando + config.
source "$SCRIPT_DIR/global.sh"
source "$SCRIPT_DIR/commands.sh"
source "$SCRIPT_DIR/check.sh"
source "$SCRIPT_DIR/functions.sh"
source "$SCRIPT_DIR/modules/status.sh"
source "$SCRIPT_DIR/modules/change.sh"
source "$SCRIPT_DIR/modules/update.sh"

FUNCTION="${1-}"
TARGET_BRANCH=""
COMMAND_FAILED=0
COMMAND_FAILURE_COUNT=0
# O resumo final é opt-in por comando via --summary.
SUMMARY_ENABLED=0
SUMMARY_PROCESSED=0
SUMMARY_SKIPPED=0
# CONFIG_FILE="$HOME/flockgit/config"
CONFIG_FILE="$SCRIPT_DIR/config"

isValidCommand()
{
    local command

    for command in "${COMMANDS[@]}"; do
        [[ "$command" == "$FUNCTION" ]] && return 0
    done

    return 1
}

isHelpCommand()
{
    local help_command

    for help_command in "${COMMANDSHELP[@]}"; do
        [[ "$help_command" == "$FUNCTION" ]] && return 0
    done

    return 1
}

# SE NÃO FOR PASSADO NENHUM PARÂMETRO, MOSTRA O HELP
if [[ -z "$FUNCTION" ]]; then 
    printf "%s%s%s\n\n" "$YELLOW" "Access help, command: flockgit -h" "$RESET"
    exit;
fi

# SE O PARÂMETRO É -h OU --help, MOSTRA OS COMANDOS
if isHelpCommand; then
    commands
    exit;
fi 

# SE O PARÂMETRO NÃO É UM COMANDO VÁLIDO, MOSTRA O ERRO
if ! isValidCommand; then
    printf "%s%s: %s%s\n\n" "$YELLOW" "Command not found" "$FUNCTION" "$RESET"
    commands
    exit 1
fi

parseArguments()
{
    local arg

    # O primeiro argumento já foi consumido como comando.
    shift
    for arg in "$@"; do
        case "$arg" in
            --summary)
                SUMMARY_ENABLED=1
                ;;
            *)
                # Apenas "change" aceita um argumento posicional extra.
                if [[ "$FUNCTION" == "change" && -z "$TARGET_BRANCH" ]]; then
                    TARGET_BRANCH="$arg"
                else
                    printf "%s%s: %s%s\n\n" "$YELLOW" "Invalid argument" "$arg" "$RESET"
                    commands
                    exit 1
                fi
                ;;
        esac
    done
}

directories()
{
    local line

    # Cada linha válida do config vira uma execução do comando sobre um repositório.
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        if ! parseConfigLine "$line"; then
            continue
        fi

        dir="$CONFIG_DIR"
        base="$CONFIG_BASE"

        # Só processa diretórios válidos e que realmente sejam repositórios Git.
        if checkDir "$dir"; then
            functions
            SUMMARY_PROCESSED=$((SUMMARY_PROCESSED + 1))
        else
            SUMMARY_SKIPPED=$((SUMMARY_SKIPPED + 1))
        fi
    done < "$CONFIG_FILE"
}

printSummary()
{
    [[ "$SUMMARY_ENABLED" -eq 1 ]] || return 0

    # O resumo ajuda no uso multi-repo sem alterar o exit code final do comando.
    printf "\nSummary: processed=%d skipped=%d failures=%d\n" \
        "$SUMMARY_PROCESSED" \
        "$SUMMARY_SKIPPED" \
        "$COMMAND_FAILURE_COUNT"
}

colors
parseArguments "$@"
# A validação global do config acontece antes de qualquer operação Git.
checkConfigFile
directories
printSummary
exit "$COMMAND_FAILED"
