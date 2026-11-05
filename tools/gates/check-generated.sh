#!/usr/bin/env bash
# feat-6-contracts-openapi-pipeline, Task 130.100 (REQ-001, REQ-005, ACC-004, ACC-009)
#
# Gate: the generated code in the repository is the code that the generators make now from contracts/openapi.yaml.
#
# Usage: check-generated.sh <backend dir> <frontend dir>
#   <backend dir>   the Maven module, for example backend. Its generated folder is <backend dir>/src/generated
#   <frontend dir>  the pnpm module, for example frontend. Its generated folder is <frontend dir>/src/generated
#
# What the gate compares with: HEAD, the commit that CI checks out (for a pull request, the merge of the pull request
# into its base). In CI the work tree is HEAD, so "the code in the repository" is the work tree. On a developer machine
# the gate gives the same result only for a work tree that has no change in the generated folders, so the gate stops for
# such a change before it generates (step 2), and it never overwrites a change that exists only in the work tree.
# The flow on a developer machine is: change contracts/openapi.yaml, `just generate`, `git add`, `git commit`,
# `just check-generated`. A change of contracts/openapi.yaml that is not committed is no problem: the gate uses the
# file of the work tree, and compares the result with the committed generated code.
#
# What the script does:
#   1. It stops (exit code 1) if a generated folder has no file in HEAD.
#   2. It stops if git does not show the true state of a generated folder before the generation, or if the work tree is
#      not HEAD there. This is the part that does not let `generate` hide a change by hand: `generate.sh` deletes the two
#      folders and makes them again, so a change that exists only in the work tree would be gone before the comparison.
#        - a file with the git flag assume-unchanged or skip-worktree (git status does not show a change of such a file);
#        - a line of `git status --porcelain --untracked-files=all --ignored` for the folders: a file that is changed,
#          deleted, staged or not tracked, and a file that .gitignore ignores (for example `Extra.class` or `x.log`).
#          git status looks at the index and at the work tree, so the gate sees untracked and ignored files too, and not only
#          the files that `git diff` knows.
#   3. It checks the marks "generated, do not change" (ACC-009, REQ-001) in the committed code: the README.md of each
#      folder, `@Generated` in each Java file, and the banner of Kubb in each TypeScript file. `generate.sh` writes them each
#      time, so a missing mark would also show in step 5, but this step gives the cause.
#   4. It starts generate.sh (`just generate`), the same script as the recipe `generate`.
#   5. It stops if `git status --porcelain --untracked-files=all --ignored` shows a line for the folders now. After step 2 the
#      work tree was HEAD, so each line is a difference between HEAD and the new generation:
#        ` M` a file of HEAD that is not the generated file: a change by hand, or a change of the OpenAPI file with no new
#             generation (the committed marker .openapi-generator/*.sha256 has the hash of the parsed OpenAPI file, so it changes too)
#        ` D` a file of HEAD that the generators do not make: an extra file in the folder (the generators delete the folder first)
#        `??` a file that the generators make and HEAD has not: a deleted generated file
#        `!!` a file that the generators make and that .gitignore ignores
#      It prints the lines and the start of `git diff HEAD`.
#
# The gate does not check the API documentation (build/api-docs, REQ-015), because the HTML is not committed.
# Exit codes: 0 pass, 1 the gate stops (a difference, a missing mark, or generate.sh fails) or the call is not correct.
# Needs git, JDK 21, Node, pnpm and the network for the first run (see generate.sh). The script changes the two generated
# folders (it makes them again) and what generate.sh changes (frontend/node_modules, ~/.m2).

set -euo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/_lib.sh"

[[ $# -eq 2 ]] || die "Usage: check-generated.sh <backend dir> <frontend dir>"
backend="$1"
frontend="$2"
[[ -d "${backend}" ]] || die "The Maven module does not exist: ${backend}"
[[ -d "${frontend}" ]] || die "The pnpm module does not exist: ${frontend}"
require_cmd git
backend="$(cd "${backend}" && pwd)"
frontend="$(cd "${frontend}" && pwd)"

# git with the settings that the gate needs: the mode of a file counts (core.fileMode), and no rename detection.
# The repository is the one of WORK_ROOT (the repository root, or GATE_WORK_ROOT for a test).
g() { git -C "${WORK_ROOT}" -c core.fileMode=true -c status.renames=false -c status.showUntrackedFiles=all "$@"; }
top="$(g rev-parse --show-toplevel 2>/dev/null)" || die "${WORK_ROOT} is not a git work tree."
top="$(cd "${top}" && pwd)"

folders=()
for module in "${backend}" "${frontend}"; do
    folder="${module}/src/generated"
    case "${folder}" in
        "${top}"/*) folders+=("${folder#"${top}"/}") ;;
        *) die "${folder} is not in the repository ${top}." ;;
    esac
done
log "Generated folders: ${folders[*]}"

stop() { echo "[$(basename "${0}")] STOP: $*" >&2; }
stopped=0

# status_lines: the lines of git status for the folders. The files of a clean folder give no line.
status_lines() { g status --porcelain --untracked-files=all --ignored -- "${folders[@]}"; }

# --- 1. Each folder has files in HEAD ---------------------------------------------------------------------------------
g rev-parse --verify --quiet 'HEAD^{commit}' >/dev/null || die "The repository has no commit (HEAD)."
for folder in "${folders[@]}"; do
    if [[ -z "$(g ls-tree -r --name-only HEAD -- "${folder}")" ]]; then
        stop "${folder} has no file in HEAD. The generated code is committed to git (REQ-005): run \`just generate\` and commit the folder."
        stopped=1
    fi
done
[[ ${stopped} -eq 0 ]] || { echo "RESULT: STOP. A generated folder is not in the repository." >&2; exit 1; }

# --- 2. The work tree is HEAD in the folders, and git shows the true state -----------------------------------------------
flagged="$(g ls-files -v -- "${folders[@]}" | grep -v '^H ' || true)"
if [[ -n "${flagged}" ]]; then
    stop "a file in a generated folder has the git flag assume-unchanged or skip-worktree (git status would not show a change of it):"
    echo "${flagged}" | sed -e 's/^/    | /' >&2
    stopped=1
fi
before="$(status_lines)"
if [[ -n "${before}" ]]; then
    stop "the generated folders are not the same as HEAD before the generation (a change by hand, an untracked or an ignored file, or a change that is not committed). The gate compares HEAD with a new generation, and the generation would overwrite this state:"
    echo "${before}" | sed -e 's/^/    | /' >&2
    echo "     The legend of git status: ' M' changed, ' D' deleted, 'M ' 'A ' 'D ' staged, '??' not tracked, '!!' ignored by .gitignore. Commit the change (after \`just generate\`) or remove it." >&2
    stopped=1
fi
[[ ${stopped} -eq 0 ]] || { echo "RESULT: STOP. The generated folders are not clean before the generation." >&2; exit 1; }

# --- 3. The marks "generated, do not change" (ACC-009) --------------------------------------------------------------------
marks_missing=0
mark_text='Generated code, do not change'
java_dir="${backend}/src/generated"
ts_dir="${frontend}/src/generated"
for dir in "${java_dir}" "${ts_dir}"; do
    if [[ ! -f "${dir}/README.md" ]] || ! grep -q "^# ${mark_text}\$" "${dir}/README.md"; then
        stop "${dir#"${top}"/}/README.md does not exist or has no title \"${mark_text}\" (the mark of the folder, ACC-009)."
        marks_missing=1
    fi
done
java_count=0
while IFS= read -r file; do
    java_count=$((java_count + 1))
    if ! grep -q '^@Generated(' "${file}"; then
        stop "${file#"${top}"/} has no @Generated annotation (the mark of the file, ACC-009)."
        marks_missing=1
    fi
done < <(find "${java_dir}" -type f -name '*.java' | LC_ALL=C sort)
ts_count=0
while IFS= read -r file; do
    ts_count=$((ts_count + 1))
    if ! grep -q '^\* Generated by Kubb (https://kubb.dev/)\.$' "${file}" || ! grep -q '^\* Do not edit manually\.$' "${file}"; then
        stop "${file#"${top}"/} has no banner of Kubb (\"Generated by Kubb ... Do not edit manually.\", the mark of the file, ACC-009)."
        marks_missing=1
    fi
done < <(find "${ts_dir}" -type f -name '*.ts' | LC_ALL=C sort)
if [[ ${java_count} -eq 0 || ${ts_count} -eq 0 ]]; then
    stop "a generated folder has no Java file (found ${java_count}) or no TypeScript file (found ${ts_count})."
    marks_missing=1
fi
[[ ${marks_missing} -eq 0 ]] || { echo "RESULT: STOP. A mark \"generated, do not change\" is missing." >&2; exit 1; }
log "The marks are in HEAD: the README.md of each folder, @Generated in ${java_count} Java file(s), the banner of Kubb in ${ts_count} TypeScript file(s)"

# --- 4. Generate again ------------------------------------------------------------------------------------------------------
generate_log="$(mktemp)"
trap 'rm -f "${generate_log}"' EXIT
log "Generate again: generate.sh ${backend} ${frontend}"
if ! "${GATES_DIR}/generate.sh" "${backend}" "${frontend}" >"${generate_log}" 2>&1; then
    tail -n 40 "${generate_log}" >&2
    stop "generate.sh failed (see above), so the generated code cannot be compared."
    echo "RESULT: STOP. The generation failed." >&2
    exit 1
fi

# --- 5. Compare with HEAD ------------------------------------------------------------------------------------------------------
after="$(status_lines)"
if [[ -n "${after}" ]]; then
    stop "the code that the generators make now is not the code of HEAD:"
    echo "${after}" | sed -e 's/^/    | /' >&2
    echo "     ' M' the generated file is not the file of HEAD (a change by hand, or a change of contracts/openapi.yaml with no new generation)." >&2
    echo "     ' D' HEAD has a file that the generators do not make (an extra file in the folder)." >&2
    echo "     '??' the generators make a file that HEAD has not (a deleted generated file), '!!' the same, and .gitignore ignores it." >&2
    echo "     Run \`just generate\` and commit the result. Do not change a generated file by hand (see contracts/README.md)." >&2
    echo "     The diff below goes from HEAD to the new generation: a line with '-' is in HEAD only, a line with '+' is in the new generation only." >&2
    g diff --stat HEAD -- "${folders[@]}" | sed -e 's/^/    | /' >&2 || true
    g diff HEAD -- "${folders[@]}" | head -n 60 | sed -e 's/^/    | /' >&2 || true
    echo "RESULT: STOP. The generated code in the repository is not the generated code of contracts/openapi.yaml." >&2
    exit 1
fi
tracked="$(g ls-files -- "${folders[@]}" | wc -l)"
log "PASS. The generated code (${tracked} files in ${folders[*]}) is the same as the new generation: no file is changed, deleted, extra, not tracked or ignored."
