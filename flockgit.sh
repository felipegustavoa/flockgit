if [ -n "${ZSH_VERSION:-}" ]; then
  FLOCKGIT_ROOT="${${(%):-%N}:A:h}"
elif [ -n "${BASH_VERSION:-}" ]; then
  FLOCKGIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  FLOCKGIT_ROOT="$(pwd)"
fi

# Garante que o setup rode apenas quando o arquivo for carregado com source.
if [ -n "${ZSH_VERSION:-}" ]; then
  case ${ZSH_EVAL_CONTEXT:-} in *:file) : ;; *) echo "Use: . ./flockgit.sh ou . flockgit" >&2; return 1 2>/dev/null || exit 1;; esac
elif [ -n "${BASH_VERSION:-}" ]; then
  [[ ${BASH_SOURCE[0]} != "$0" ]] || { echo "Use: . ./flockgit.sh ou . flockgit" >&2; return 1 2>/dev/null || exit 1; }
else
  # Fallback POSIX: se "return" funciona aqui, é porque foi sourceado.
  (return 0 2>/dev/null) && : || { echo "Use: . ./flockgit.sh ou . flockgit" >&2; exit 1; }
fi

source "$FLOCKGIT_ROOT/aliases.sh"
