#!/usr/bin/env bash
# Check hardening Oracle — solo lectura, exit 1 si falla. Para Parte 1 (15%).
set -u
FAIL=0
chk(){ if eval "$2"; then echo "PASS: $1"; else echo "FAIL: $1"; FAIL=1; fi }
echo "== Oracle hardening check =="
chk "SELinux enforcing" '[ "$(getenforce)" = "Enforcing" ]'
chk "PermitRootLogin no" 'grep -Eq "^PermitRootLogin no" /etc/ssh/sshd_config'
chk "PasswordAuthentication no" 'grep -Eq "^PasswordAuthentication no" /etc/ssh/sshd_config'
chk "firewalld activo" 'systemctl is-active firewalld | grep -q active'
chk "http/https permitidos" 'firewall-cmd --list-services | grep -q http'
chk "samba restringido a lab" 'firewall-cmd --list-rich-rules | grep -q "192.168.56.0/24"'
chk "auditd activo" 'systemctl is-active auditd | grep -q active'
chk "reglas audit lab" '[ -f /etc/audit/rules.d/lab.rules ]'
chk "httpd activo" 'systemctl is-active httpd | grep -q active'
chk "smb activo" 'systemctl is-active smb | grep -q active'
chk "cert wiki existe" '[ -f /etc/pki/tls/certs/wiki-lab.crt ]'
chk "share academico 2770" '[ "$(stat -c %a /srv/samba/academico)" = "2770" ]'
chk "testparm OK" 'testparm -s >/dev/null 2>&1'
chk "HTTPS 200/302" 'curl -sk -o /dev/null -w "%{http_code}" https://localhost/ | grep -Eq "200|302"'
exit $FAIL
