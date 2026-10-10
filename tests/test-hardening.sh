#!/usr/bin/env bash
# test-hardening wrapper: ejecuta checks Oracle/FreeBSD vía ssh si hay acceso, si no indica manual.
set -u
echo "== test-hardening =="
echo "-- Oracle (vagrant ssh oracle-web) --"
vagrant ssh oracle-web -c "sudo bash /vagrant/security/oracle-hardening-check.sh" 2>&1 || echo "PENDIENTE: ejecutar en oracle-web tras up"
echo "-- FreeBSD (vagrant ssh freebsd-ftp) --"
vagrant ssh freebsd-ftp -c "sudo sh /vagrant/security/freebsd-hardening-check.sh" 2>&1 || echo "PENDIENTE: ejecutar en freebsd-ftp tras up"
echo "-- Windows: ejecutar security/windows-audit.ps1 vía WinRM --"
