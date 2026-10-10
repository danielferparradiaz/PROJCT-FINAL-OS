#!/usr/bin/env bash
# validate-lab.sh — validación no destructiva post-provisión (host con acceso a 192.168.56.0/24).
set -u
echo "== validate-lab =="
vagrant validate || echo "WARN vagrant validate falló"
vagrant status
bash tests/test-services.sh
echo "--- hardening (requiere ssh a guests) ---"
vagrant ssh oracle-web -c "sudo bash /vagrant/security/oracle-hardening-check.sh" 2>/dev/null || echo "INFO: ejecutar manual: vagrant ssh oracle-web"
vagrant ssh freebsd-ftp -c "sudo sh /vagrant/security/freebsd-hardening-check.sh" 2>/dev/null || echo "INFO: ejecutar manual en freebsd"
echo "--- Windows: ejecutar security/windows-audit.ps1 vía WinRM/RDP ---"
echo "validate-lab terminado (ver PROGRESS.md para registrar evidencias reales)."
