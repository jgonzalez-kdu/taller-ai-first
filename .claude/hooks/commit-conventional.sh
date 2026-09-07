#!/usr/bin/env bash
# PreToolUse hook (Bash matcher): blocks `git commit` calls whose message
# doesn't follow Conventional Commits (https://www.conventionalcommits.org).
set -euo pipefail

input="$(cat)"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // empty')"

if [[ -z "$command" ]]; then
  exit 0
fi

export CC_HOOK_COMMAND="$command"

python3 <<'PYEOF'
import json
import os
import re
import sys

command = os.environ.get("CC_HOOK_COMMAND", "")

# Only look at commands that actually invoke `git commit` as a subcommand.
# Anchored on a `git` ... `commit` pair with no command separator (;, &, |)
# in between, so global flags with a space-separated value (e.g.
# `git -c commit.gpgsign=false commit -m ...`) don't hide the subcommand.
if not re.search(r"\bgit\b(?:(?!\bcommit\b|[;&|]).)*?\bcommit\b", command, re.S):
    sys.exit(0)


def extract_message(cmd: str):
    # Heredoc style, e.g. git commit -m "$(cat <<'EOF' ... EOF )"
    m = re.search(r"<<[-~]?['\"]?(\w+)['\"]?\s*\n(.*?)\n\1\b", cmd, re.S)
    if m:
        body = m.group(2)
        first_line = next((l for l in body.splitlines() if l.strip()), "")
        return first_line.strip()

    # -m "message" / -m 'message' / -am "message" / --message="message"
    m = re.search(
        r"(?:-[a-zA-Z]*m[a-zA-Z]*|--message)(?:=|\s+)(\"([^\"]*)\"|'([^']*)')",
        cmd,
    )
    if m:
        msg = m.group(2) if m.group(2) is not None else m.group(3)
        first_line = next((l for l in msg.splitlines() if l.strip()), "")
        return first_line.strip()

    return None


message = extract_message(command)

if message is None:
    # No inline message we can inspect (interactive editor, --amend --no-edit,
    # -F <file>, -C <commit>, plain merge commit, etc.) -> nothing to validate.
    sys.exit(0)

CONVENTIONAL_TYPES = (
    "build", "chore", "ci", "docs", "feat", "fix",
    "perf", "refactor", "revert", "style", "test",
)
pattern = re.compile(
    r"^(" + "|".join(CONVENTIONAL_TYPES) + r")(\([a-zA-Z0-9_./-]+\))?(!)?: .+"
)

if pattern.match(message):
    sys.exit(0)

reason = (
    f'Mensaje de commit rechazado: "{message}"\n'
    "No sigue Conventional Commits. Formato esperado: <tipo>[(scope)][!]: <descripcion>\n"
    f"Tipos válidos: {', '.join(CONVENTIONAL_TYPES)}.\n"
    'Ejemplo: fix(carrito): corrige el calculo del descuento'
)

print(reason, file=sys.stderr)
print(json.dumps({
    "decision": "block",
    "reason": reason,
    "hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "permissionDecision": "deny",
        "permissionDecisionReason": reason,
    },
}))
sys.exit(0)
PYEOF
