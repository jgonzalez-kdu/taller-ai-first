#!/usr/bin/env bash
# Gates de calidad que deben pasar antes de abrir un PR:
#   1. ruff check sobre src/ y tests/, sin hallazgos.
#   2. bandit sobre src/, sin hallazgos de severidad media o alta.
#   3. pytest en verde.
#   4. Conventional Commits en todos los commits de la rama actual contra main.
#
# Muestra la salida de cada control y termina con código 1 si alguno falla,
# o 0 si todos pasan. No hace early-exit: corre los cuatro para dar un
# reporte completo de una sola vez.
set -uo pipefail

cd "$(git rev-parse --show-toplevel)"

BASE_BRANCH="${GATES_BASE_BRANCH:-main}"
FAILED=0

separator() { printf '==================================================\n'; }

run_gate() {
  local name="$1"
  shift
  separator
  echo "GATE: $name"
  echo "\$ $*"
  echo "--------------------------------------------------"
  "$@"
  local status=$?
  echo "--------------------------------------------------"
  if [[ $status -eq 0 ]]; then
    echo "OK: $name"
  else
    echo "FALLÓ: $name (código de salida $status)"
    FAILED=1
  fi
  echo
}

# 1. ruff check sobre src/ y tests/
run_gate "ruff check (src/ tests/)" uvx ruff check src/ tests/

# 2. bandit sobre src/, solo severidad media/alta (-ll = MEDIUM y HIGH)
run_gate "bandit -r src/ (severidad media/alta)" uvx bandit -r src/ -ll

# 3. pytest en verde
run_gate "pytest" uv run pytest

# 4. Conventional Commits en todos los commits de la rama vs main
CURRENT_BRANCH="$(git branch --show-current)"

separator
echo "GATE: Conventional Commits ($BASE_BRANCH..${CURRENT_BRANCH:-HEAD})"
echo "--------------------------------------------------"

if [[ -z "$CURRENT_BRANCH" ]]; then
  echo "No se pudo determinar la rama actual (HEAD detached)."
  echo "--------------------------------------------------"
  echo "FALLÓ: Conventional Commits"
  FAILED=1
elif [[ "$CURRENT_BRANCH" == "$BASE_BRANCH" ]]; then
  echo "La rama actual es '$BASE_BRANCH': no hay commits que comparar contra sí misma."
  echo "--------------------------------------------------"
  echo "FALLÓ: Conventional Commits"
  FAILED=1
else
  PATTERN='^(build|chore|ci|docs|feat|fix|perf|refactor|revert|style|test)(\([a-zA-Z0-9_./-]+\))?(!)?: .+'
  COMMITS_FAILED=0
  COMMIT_COUNT=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    COMMIT_COUNT=$((COMMIT_COUNT + 1))
    sha="${line%% *}"
    subject="${line#* }"
    if [[ "$subject" =~ $PATTERN ]]; then
      echo "OK    $sha  $subject"
    else
      echo "MAL   $sha  $subject"
      COMMITS_FAILED=1
    fi
  done < <(git log --no-merges --pretty=format:'%h %s' "$BASE_BRANCH..$CURRENT_BRANCH"; echo)

  if [[ $COMMIT_COUNT -eq 0 ]]; then
    echo "No hay commits en $CURRENT_BRANCH que no estén ya en $BASE_BRANCH."
  fi

  echo "--------------------------------------------------"
  if [[ $COMMITS_FAILED -eq 0 ]]; then
    echo "OK: Conventional Commits"
  else
    echo "FALLÓ: Conventional Commits"
    FAILED=1
  fi
fi
echo

separator
if [[ $FAILED -eq 0 ]]; then
  echo "RESULTADO: TODOS LOS GATES PASARON"
  exit 0
else
  echo "RESULTADO: AL MENOS UN GATE FALLÓ"
  exit 1
fi
