#!/bin/bash

parseConfigLine()
{
    local REST="$1"
    local KEY
    local VALUE

    # O parser popula variáveis globais para reaproveitar o resultado no loop do prompt.
    CONFIG_DIR=""
    CONFIG_BASE=""
    CONFIG_ERROR=""

    while [[ -n "$REST" ]]; do
        [[ "$REST" =~ ^[[:space:]]*$ ]] && break
        [[ "$REST" =~ ^[[:space:]]*# ]] && break

        if [[ "$REST" =~ ^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)=(\"[^\"]*\"|\'[^\']*\'|[^[:space:]#]+)(.*)$ ]]; then
            KEY="${BASH_REMATCH[1]}"
            VALUE="${BASH_REMATCH[2]}"
            REST="${BASH_REMATCH[3]}"

            # Aspas são aceitas apenas para permitir espaços no valor do campo.
            if [[ "$VALUE" =~ ^\".*\"$ || "$VALUE" =~ ^\'.*\'$ ]]; then
                VALUE="${VALUE:1:${#VALUE}-2}"
            fi

            case "$KEY" in
                dir) CONFIG_DIR="$VALUE" ;;
                base) CONFIG_BASE="$VALUE" ;;
                *)
                    CONFIG_ERROR="Unknown key: $KEY"
                    return 1
                    ;;
            esac
        else
            CONFIG_ERROR="Invalid token"
            return 1
        fi
    done

    if [[ -z "$CONFIG_DIR" || -z "$CONFIG_BASE" ]]; then
        CONFIG_ERROR="Missing required keys: dir and base"
        return 1
    fi

    return 0
}

checkConfigFile()
{
    local line
    local line_number=0
    local valid_entries=0

    # Falha cedo se o arquivo de configuração não existir.
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_number++))

        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        if parseConfigLine "$line"; then
            ((valid_entries++))
        else
            if [[ -n "$CONFIG_ERROR" ]]; then
                printf "Invalid config line %d (%s): %s\n" "$line_number" "$CONFIG_ERROR" "$line" >&2
            else
                printf "Invalid config line %d: %s\n" "$line_number" "$line" >&2
            fi
        fi
    done < "$CONFIG_FILE"

    # O arquivo precisa ter ao menos um repositório válido para seguir.
    if [[ "$valid_entries" -eq 0 ]]; then
        printf "Configuration file with no repositories defined: %s\n" "$CONFIG_FILE" >&2
        printf "Add one repository per line, for example:\n" >&2
        printf "dir=/path/to/project base=main\n" >&2
        printf "dir=\"/path/with spaces/project\" base=master\n" >&2
        exit 1
    fi
}

checkDir()
{
    local DIR="$1"

    # Diretórios inválidos são ignorados na execução em vez de quebrar o comando inteiro.
    if [[ ! -d "$DIR" ]]; then
        return 1
    fi

    # Só considera diretórios que sejam repositórios Git válidos.
    if ! git -C "$DIR" rev-parse --git-dir >/dev/null 2>&1; then
        return 1
    fi

    return 0
}
