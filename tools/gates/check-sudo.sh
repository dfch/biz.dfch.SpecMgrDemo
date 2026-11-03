#!/usr/bin/env bash
# feat-5-foundation-monorepo-ci, Task 130.145 (REQ-008, ACC-011)
#
# Gate: no script of the project uses sudo.
#
# Usage: check-sudo.sh <path>...
#   Each <path> is a folder or a file. The script looks at these files in each folder:
#   *.sh, *.bash, *.just, justfile, *.yml and *.yaml (not in node_modules and not in .git).
#
# The gate stops (exit code 1) if a line of such a file has the word `sudo` (or `doas` or
# `pkexec`) as a word of a command: at the start of the line, or after a space, `;`, `&`, `|`,
# a bracket, a quote, `/` (a path like /usr/bin/sudo), `\` or `=`. A name such as
# `check-sudo.sh` is not a command, because `-` is not in this list. The gate does not look at
# lines that start with `#` (a comment, for example "this script does not use sudo"). It is a
# check of the text. It is not a proof: a script can write the word in a way that the text check
# does not see. The second part of ACC-011, that the scripts operate for a user that has no sudo,
# is shown by the run of the install scripts and the gates on a machine where the user has no sudo.
# Exit codes: 0 no finding, 1 a finding, 2 no file to check or a path that does not exist.

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -ge 1 ]] || die "Usage: check-sudo.sh <path>..."
require_cmd grep
require_cmd find

# The words, at the start of a command (see the header). The script writes the words in parts, so
# that its own lines do not have them. A gate must not stop for its own text.
words="su""do|do""as|pk""exec"
pattern=$'(?i)(^|[\\s;&|(){}`"\'/\\\\=])('"${words}"$')($|[\\s;&|(){}`"\'])'

files=()
for path in "$@"; do
    if [[ -f "${path}" ]]; then
        files+=("${path}")
    elif [[ -d "${path}" ]]; then
        while IFS= read -r -d '' file; do
            files+=("${file}")
        done < <(find "${path}" \( -name node_modules -o -name .git \) -prune -o -type f \
            \( -name '*.sh' -o -name '*.bash' -o -name '*.just' -o -name 'justfile' -o -name '*.yml' -o -name '*.yaml' \) \
            -print0 | sort -z)
    else
        echo "[check-sudo.sh] ERROR: ${path} does not exist." >&2
        exit 2
    fi
done

if [[ ${#files[@]} -eq 0 ]]; then
    echo "[check-sudo.sh] ERROR: no file to check in: $*" >&2
    exit 2
fi

findings=0
for file in "${files[@]}"; do
    # grep -n gives "<line>:<text>". Remove the lines of comments.
    matches="$({ grep -nP -- "${pattern}" "${file}" || true; } | { grep -vP '^[0-9]+:\s*#' || true; })"
    if [[ -n "${matches}" ]]; then
        while IFS= read -r match; do
            echo "STOP ${file}:${match}"
            findings=$((findings + 1))
        done <<<"${matches}"
    fi
done

if [[ ${findings} -gt 0 ]]; then
    echo "[check-sudo.sh] ${findings} line(s) with a command to get more rights in ${#files[@]} file(s). The scripts must not use sudo." >&2
    exit 1
fi
log "${#files[@]} file(s) checked, no command to get more rights. PASS"
