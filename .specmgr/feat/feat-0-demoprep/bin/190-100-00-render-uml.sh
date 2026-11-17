#!/usr/bin/env bash
# Task 190.100 (ACC-014): render each uml/*.puml to an SVG file in uml/ (committed) with a PlantUML server (the default is the
# container "plantuml-server" at http://127.0.0.1:8080). It stops for a diagram that the server cannot draw (a syntax error or the
# crash page of PlantUML 1.2026.8). The server gets the text of the diagram (the encoded URL), and no other service is used.
# Usage: 190-100-00-render-uml.sh [<file.puml> ...]    (no argument: all files in uml/)
source "$(dirname "${BASH_SOURCE[0]}")/_common.sh"
need curl; need python3
PLANTUML_BASE="${PLANTUML_BASE:-http://127.0.0.1:8080}"
UML="${FEAT_DIR}/uml"
(( $# > 0 )) && files=("$@") || files=("${UML}"/*.puml)
fail=0
for f in "${files[@]}"; do
    out="${f%.puml}.svg"
    enc="$(python3 "${BIN_DIR}/190-100-01-encode.py" "${f}")"
    code="$(curl -sS -o "${out}.tmp" -w '%{http_code}' "${PLANTUML_BASE}/svg/${enc}")" || die "The server ${PLANTUML_BASE} is not reachable."
    if [[ "${code}" == "200" ]] && head -c 400 "${out}.tmp" | grep -q '<svg' && ! grep -q -e 'has crashed' -e 'Welcome to PlantUML' "${out}.tmp"; then
        mv "${out}.tmp" "${out}"; log "OK   $(basename "${out}") ($(wc -c <"${out}") bytes)"
    else
        rm -f "${out}.tmp"; log "FAIL $(basename "${f}") (HTTP ${code})"; fail=1
    fi
done
(( fail == 0 )) || exit 1
log "PASS ${#files[@]} diagram(s)"
