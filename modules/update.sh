#!/bin/bash

update()
{
    local DIR="$1"
    local BASE="$2"
    local current
    local upstream_ref
    local remote_name
    local remote_branch

    # O update sempre age sobre a branch atual do repositório.
    current="$(git -C "$DIR" branch --show-current)"
    upstream_ref="$(gitUpstreamRef "$DIR" "$current")"

    # Não assume "origin"; usa o upstream real configurado no Git.
    if [[ -n "$upstream_ref" ]]; then
        remote_name="${upstream_ref%%/*}"
        remote_branch="${upstream_ref#*/}"

        # A falha é registrada, mas não interrompe o processamento dos outros repositórios.
        if ! git -C "$DIR" pull "$remote_name" "$remote_branch"; then
            markCommandFailure "pull failed" "$DIR"
        fi
    fi 

    status "$DIR" "$BASE"
}
