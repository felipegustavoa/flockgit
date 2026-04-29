#!/bin/bash

markCommandFailure()
{
    local MESSAGE="$1"
    local DIR="$2"

    # A CLI continua nos outros repositórios, mas propaga falha ao final.
    COMMAND_FAILED=1
    COMMAND_FAILURE_COUNT=$((COMMAND_FAILURE_COUNT + 1))
    printf "%s (%s)\n" "$MESSAGE" "$(basename "$DIR")" >&2
}

gitUpstreamRef()
{
    local DIR="$1"
    local BRANCH="$2"

    # Resolve o upstream simbólico completo, como "origin/main".
    git -C "$DIR" rev-parse --abbrev-ref --symbolic-full-name "${BRANCH}@{upstream}" 2>/dev/null
}

gitUpstreamRemote()
{
    local DIR="$1"
    local BRANCH="$2"
    local UPSTREAM

    UPSTREAM="$(gitUpstreamRef "$DIR" "$BRANCH")" || return 1
    printf "%s\n" "${UPSTREAM%%/*}"
}

findRemoteBranchRef()
{
    local DIR="$1"
    local BRANCH="$2"

    # Usa refs já conhecidas localmente antes de consultar a rede.
    git -C "$DIR" for-each-ref --format='%(refname:short)' "refs/remotes/*/$BRANCH" | head -n 1
}

findRemoteBranchSource()
{
    local DIR="$1"
    local BRANCH="$2"
    local REMOTE_REF
    local REMOTE_NAME

    # Primeiro tenta refs já conhecidas localmente para evitar rede desnecessária.
    REMOTE_REF="$(findRemoteBranchRef "$DIR" "$BRANCH")"
    if [[ -n "$REMOTE_REF" ]]; then
        printf "%s\n" "$REMOTE_REF"
        return 0
    fi

    # Se não achar localmente, pergunta aos remotos configurados do repo.
    while IFS= read -r REMOTE_NAME; do
        [[ -z "$REMOTE_NAME" ]] && continue

        if git -C "$DIR" ls-remote --exit-code --heads "$REMOTE_NAME" "$BRANCH" >/dev/null 2>&1; then
            printf "%s/%s\n" "$REMOTE_NAME" "$BRANCH"
            return 0
        fi
    done < <(git -C "$DIR" remote)

    return 1
}

functions() {
    # Cada linha válida do config delega para exatamente um módulo.
    case "$FUNCTION" in
        status)
            status "$dir" "$base"
            ;;
        update)
            update "$dir" "$base"
            ;;
        change)
            change "$dir" "$base" "$TARGET_BRANCH"
            ;;
    esac
}
