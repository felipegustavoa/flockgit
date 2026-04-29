#!/bin/bash

change()
{
    local DIR="$1"
    local BASE="$2"
    local BRANCH="$3"
    local CURRENT_BRANCH
    local REMOTE_REF
    local REMOTE_NAME
    local REMOTE_BRANCH
    local UPSTREAM_REF
    local UPSTREAM_REMOTE
    local UPSTREAM_BRANCH
    local BRANCH_FOUND=0

    # "main" e "master" viram a base configurada por repositório.
    if [[ "$BRANCH" =~ ^(master|main)$ ]]; then 
        BRANCH="$BASE"
    fi 

    if [[ -z "$BRANCH" ]]; then
        # Sem branch alvo, o comando vira apenas uma visualização de status desse repo.
        status "$DIR" "$BASE"
        return 0
    fi

    # Não troca de branch se houver mudanças locais pendentes.
    if [[ -n "$(git -C "$DIR" status --porcelain)" ]]; then
        status "$DIR" "$BASE"
        return 0
    fi

    CURRENT_BRANCH="$(git -C "$DIR" branch --show-current)"

    # Primeiro tenta a branch local; só consulta remoto se necessário.
    if git -C "$DIR" show-ref --verify --quiet "refs/heads/$BRANCH"; then
        BRANCH_FOUND=1
        if [[ "$CURRENT_BRANCH" != "$BRANCH" ]]; then
            if ! git -C "$DIR" switch -q -- "$BRANCH"; then
                markCommandFailure "switch failed" "$DIR"
                status "$DIR" "$BASE"
                return 0
            fi
        fi

    # Se achar no remoto, cria a branch local rastreando o upstream encontrado.
    else
        REMOTE_REF="$(findRemoteBranchSource "$DIR" "$BRANCH")"
        if [[ -n "$REMOTE_REF" ]]; then
            BRANCH_FOUND=1
            REMOTE_NAME="${REMOTE_REF%%/*}"
            REMOTE_BRANCH="${REMOTE_REF#*/}"
            if ! git -C "$DIR" fetch "$REMOTE_NAME" "$REMOTE_BRANCH"; then
                markCommandFailure "fetch failed" "$DIR"
                status "$DIR" "$BASE"
                return 0
            fi

            if ! git -C "$DIR" switch -q -c "$BRANCH" --track "$REMOTE_NAME/$REMOTE_BRANCH"; then
                markCommandFailure "switch failed" "$DIR"
                status "$DIR" "$BASE"
                return 0
            fi
        fi
    fi

    if [[ "$BRANCH_FOUND" -eq 0 ]]; then
        # Por decisão de produto, branch inexistente não vira erro nem aviso extra.
        status "$DIR" "$BASE"
        return 0
    fi

    # Depois da troca, tenta sincronizar apenas se houver upstream configurado.
    if git -C "$DIR" show-ref --verify --quiet "refs/heads/$BRANCH"; then
        UPSTREAM_REF="$(gitUpstreamRef "$DIR" "$BRANCH")"
        if [[ -n "$UPSTREAM_REF" ]]; then
            UPSTREAM_REMOTE="${UPSTREAM_REF%%/*}"
            UPSTREAM_BRANCH="${UPSTREAM_REF#*/}"
            if ! git -C "$DIR" pull "$UPSTREAM_REMOTE" "$UPSTREAM_BRANCH"; then
                markCommandFailure "pull failed" "$DIR"
            fi
        fi
    fi

    status "$DIR" "$BASE"
}
