#!/usr/bin/env bash
# collect-evidence.sh — recoge salidas anonimizadas a evidence/ (no incluye passwords).
set -u
mkdir -p evidence
date -u > evidence/run-$(date +%F-%H%M).txt
vagrant status >> evidence/run-$(date +%F-%H%M).txt 2>&1 || true
bash tests/test-services.sh 2>&1 | sed -E 's/[Pp]assword[^ ]*/password ***/g' >> evidence/run-$(date +%F-%H%M).txt || true
echo "Evidencia guardada. Añadir capturas manuales (RDP/browser) a evidence/ (ver evidence/README.md)."
