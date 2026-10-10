#!/usr/bin/env bash
# check-prereqs.sh — macOS/Linux. Verifica arch, RAM, disco, vagrant, provider, boxes.
set -u
FAIL=0
echo "== prereqs (host lab debe ser x86_64) =="
uname -m | grep -Eq "x86_64|amd64" && echo "PASS arch $(uname -m)" || { echo "FAIL arch $(uname -m): este host NO puede correr Win x64 nativo (ver COMPATIBILITY.md)"; FAIL=1; }
command -v vagrant >/dev/null && echo "PASS vagrant $(vagrant --version)" || { echo "FAIL vagrant no instalado"; FAIL=1; }
command -v VBoxManage >/dev/null && echo "PASS VirtualBox $(VBoxManage --version)" || echo "WARN VirtualBox no encontrado (alternativa: vmware)"
command -v vmrun >/dev/null && echo "PASS vmware vmrun" || echo "INFO vmware no detectado"
# RAM/disco (Linux/macOS)
if command -v free >/dev/null; then free -g | head -2; else sysctl hw.memsize 2>/dev/null || true; fi
df -h . | tail -1
echo "--- boxes (si falta alguna: vagrant box add ...) ---"
vagrant box list 2>/dev/null || echo "WARN no se pudo listar boxes"
echo "Red lab esperada 192.168.56.0/24; desactivar DHCP VirtualBox en esa host-only (ver NETWORK.md)."
exit $FAIL
