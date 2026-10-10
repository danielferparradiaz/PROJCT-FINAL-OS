#!/usr/bin/env bash
# snapshot.sh — guardar/restaurar snapshots pre-demo. Uso: bash scripts/snapshot.sh save|restore <tag>
set -u
ACT=${1:-save}; TAG=${2:-predemo}
for vm in windows-dc oracle-web freebsd-ftp windows-client; do
  if [ "$ACT" = "save" ]; then vagrant snapshot save $vm $TAG; else vagrant snapshot restore $vm $TAG; fi
done
