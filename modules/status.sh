#!/bin/bash

status()
{
    local DIR="$1"
    local BRANCH
    local COLOR
    local FLAGS=()
    local UPSTREAM
    local COUNTS
    local AHEAD
    local BEHIND

    # Trata HEAD detached como um estado válido para exibição.
    BRANCH="$(git -C "$DIR" branch --show-current)"
    [[ -z "$BRANCH" ]] && BRANCH="detached"

    # "dirty" continua sendo o principal indicador visual do status local.
    COLOR="$GREEN"
    if [[ -n "$(git -C "$DIR" status --porcelain)" ]]; then
        COLOR="$RED"
        FLAGS+=("dirty")
    fi 

    UPSTREAM="$(git -C "$DIR" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"
    if [[ -n "$UPSTREAM" ]]; then
        COUNTS="$(git -C "$DIR" rev-list --left-right --count "${UPSTREAM}...HEAD" 2>/dev/null)"
        BEHIND="${COUNTS%%[[:space:]]*}"
        AHEAD="${COUNTS##*[[:space:]]}"

        if [[ "${AHEAD:-0}" -gt 0 ]]; then
            FLAGS+=("ahead:${AHEAD}")
        fi

        if [[ "${BEHIND:-0}" -gt 0 ]]; then
            FLAGS+=("behind:${BEHIND}")
        fi
    else
        FLAGS+=("no-remote")
    fi

    # Exibe também o estado de sincronização com o upstream quando existir.
    if [[ "${#FLAGS[@]}" -gt 0 ]]; then
        printf "%s%s%s - %s [%s]\n" "$COLOR" "$BRANCH" "$RESET" "$(basename "$DIR")" "${FLAGS[*]}"
    else
        printf "%s%s%s - %s\n" "$COLOR" "$BRANCH" "$RESET" "$(basename "$DIR")"
    fi
}
