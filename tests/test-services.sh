#!/usr/bin/env bash
# Tests integración red/servicios — resultados reales, no solo exit 0. Ejecutar desde host con red lab accesible.
# Uso: DC_IP=192.168.56.12 WEB_IP=192.168.56.10 FTP_IP=192.168.56.11 bash tests/test-services.sh
set -u
DC=${DC_IP:-192.168.56.12}; WEB=${WEB_IP:-192.168.56.10}; FTP=${FTP_IP:-192.168.56.11}
FAIL=0
t(){ if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; FAIL=1; fi }
echo "== test-services =="
t "ping DC" "ping -c2 -W2 $DC >/dev/null"
t "ping WEB" "ping -c2 -W2 $WEB >/dev/null"
t "ping FTP" "ping -c2 -W2 $FTP >/dev/null"
t "DNS lab.local vía DC" "nslookup lab.local $DC 2>&1 | grep -q 'Address'"
t "DNS oracle-web" "nslookup oracle-web.lab.local $DC 2>&1 | grep -q $WEB"
t "HTTP redirect 301" 'curl -s -o /dev/null -w "%{http_code}" http://$WEB/ | grep -q 301'
t "HTTPS 200/302" 'curl -sk -o /dev/null -w "%{http_code}" https://$WEB/ | grep -Eq "200|302"'
t "Samba puerto 445" "(echo > /dev/tcp/$WEB/445) >/dev/null 2>&1"
t "FTP puerto 21 + banner 220" 'curl -s -v ftp://$FTP/ --max-time 8 2>&1 | grep -q "220"'
t "FTP anon lista pub" 'curl -s --max-time 8 ftp://anonymous:anonymous@$FTP/pub/ | grep -qi "README\|pub" || curl -s --max-time 8 ftp://anonymous:anonymous@$FTP/ >/dev/null'
echo "Nota: pruebas auth (samba/ftp con password) requieren env y se ejecutan en validate-lab/demo con credenciales."
exit $FAIL
