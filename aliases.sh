if [ -n "${ZSH_VERSION:-}" ]; then
  ALIASES_ROOT="${${(%):-%N}:A:h}"
elif [ -n "${BASH_VERSION:-}" ]; then
  ALIASES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  ALIASES_ROOT="$(pwd)"
fi

FLOCKGIT_BIN="$ALIASES_ROOT/prompt.sh"

if [[ ! -x "$FLOCKGIT_BIN" ]]; then
  echo "Arquivo principal não encontrado ou sem permissão de execução: $FLOCKGIT_BIN" >&2
  return 1 2>/dev/null || exit 1
fi

flockgit() {
  # A função principal mantém a CLI acessível após o source do arquivo.
  "$FLOCKGIT_BIN" "$@"
}

fg() {
  # Atalho curto para o comando principal no uso diário.
  flockgit "$@"
}

alias status="$FLOCKGIT_BIN status"
alias update="$FLOCKGIT_BIN update"
alias change="$FLOCKGIT_BIN change"

alias flockgit.status="$FLOCKGIT_BIN status"
alias flockgit.update="$FLOCKGIT_BIN update"
alias flockgit.change="$FLOCKGIT_BIN change"
alias fg.status="$FLOCKGIT_BIN status"
alias fg.update="$FLOCKGIT_BIN update"
alias fg.change="$FLOCKGIT_BIN change"

if [ -n "${ZSH_VERSION:-}" ]; then
  # Fallback para shells zsh que ainda não inicializaram o sistema de completion.
  if ! type compdef >/dev/null 2>&1; then
    autoload -Uz compinit 2>/dev/null
    compinit -u -C 2>/dev/null || true
  fi
fi

if [ -n "${ZSH_VERSION:-}" ] && type compdef >/dev/null 2>&1; then
  _flockgit_git_branch_names() {
    local -a branch_names
    # Mescla branches locais e refs remotas conhecidas para autocomplete do "change".
    branch_names=(${(f)"$( {
      git for-each-ref --format='%(refname:short)' refs/heads/
      git for-each-ref --format='%(refname:short)' refs/remotes/
    } 2>/dev/null )"})
    print -l -- $branch_names
  }

  _flockgit_change_complete() {
    local -a branch_names
    branch_names=(${(f)"$(_flockgit_git_branch_names)"})
    compadd -- $branch_names
  }

  _flockgit_complete() {
    local -a commands
    local -a root_flags
    local -a flags
    commands=(status update change)
    root_flags=(-h --help)
    flags=(--summary)

    # O primeiro token após "flockgit" sempre é um subcomando.
    if (( CURRENT == 2 )); then
      compadd -- $commands $root_flags
      return
    fi

    if [[ "${words[2]}" == "change" ]]; then
      if [[ "${words[CURRENT]}" == -* ]]; then
        compadd -- $flags
        return
      fi

      if (( CURRENT >= 3 )); then
        compadd -- $flags
        _flockgit_change_complete
        return
      fi
    elif [[ "${words[2]}" == "status" || "${words[2]}" == "update" ]]; then
      if (( CURRENT >= 3 )); then
        compadd -- $flags
        return
      fi
    fi
  }

  compdef _flockgit_change_complete change
  compdef _flockgit_change_complete flockgit.change
  compdef _flockgit_change_complete fg.change
  compdef _flockgit_complete flockgit
  compdef _flockgit_complete fg
elif [ -n "${BASH_VERSION:-}" ]; then
  _flockgit_change_complete() {
    local cur branch_names
    cur="${COMP_WORDS[COMP_CWORD]}"
    # No bash, a lista de branches também vem de refs locais + remotas conhecidas.
    branch_names="$( {
      git for-each-ref --format='%(refname:short)' refs/heads/
      git for-each-ref --format='%(refname:short)' refs/remotes/
    } 2>/dev/null )"
    COMPREPLY=( $(compgen -W "$branch_names" -- "$cur") )
  }

  _flockgit_complete() {
    local cur
    cur="${COMP_WORDS[COMP_CWORD]}"

    if [[ "$COMP_CWORD" -eq 1 ]]; then
      COMPREPLY=( $(compgen -W "status update change -h --help" -- "$cur") )
      return
    fi

    if [[ "${COMP_WORDS[1]}" == "change" ]]; then
      COMPREPLY=( $(compgen -W "--summary" -- "$cur") )

      if [[ "$COMP_CWORD" -ge 2 ]]; then
        local branch_reply=()
        local branch_names
        branch_names="$( {
          git for-each-ref --format='%(refname:short)' refs/heads/
          git for-each-ref --format='%(refname:short)' refs/remotes/
        } 2>/dev/null )"
        branch_reply=( $(compgen -W "$branch_names" -- "$cur") )
        COMPREPLY=( "${COMPREPLY[@]}" "${branch_reply[@]}" )
      fi
      return
    fi

    if [[ "$COMP_CWORD" -ge 2 && ( "${COMP_WORDS[1]}" == "status" || "${COMP_WORDS[1]}" == "update" ) ]]; then
      COMPREPLY=( $(compgen -W "--summary" -- "$cur") )
      return
    fi

    COMPREPLY=()
  }

  complete -F _flockgit_change_complete change
  complete -F _flockgit_change_complete flockgit.change
  complete -F _flockgit_change_complete fg.change
  complete -F _flockgit_complete flockgit
  complete -F _flockgit_complete fg
fi
