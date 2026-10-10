#!/usr/bin/env sh
# Check hardening FreeBSD — solo lectura.
set -u
FAIL=0
chk(){ if eval "$2" >/dev/null 2>&1; then echo "PASS: $1"; else echo "FAIL: $1"; FAIL=1; fi }
echo "== FreeBSD hardening check =="
chk "PermitRootLogin no" 'grep -Eq "^PermitRootLogin no" /etc/ssh/sshd_config'
chk "PF activo" 'pfctl -s info | grep -qi "Status.*Enabled"'
chk "PF config válida" 'pfctl -nf /etc/pf.conf'
chk "vsftpd activo" 'service vsftpd status | grep -qi running'
chk "puerto 21 escucha" 'sockstat -l | grep -q ":21"'
chk "anon sin escritura" 'grep -Eq "^anon_upload_enable=NO" /usr/local/etc/vsftpd.conf'
chk "anon mkdir off" 'grep -Eq "^anon_mkdir_write_enable=NO" /usr/local/etc/vsftpd.conf'
chk "chroot on" 'grep -Eq "^chroot_local_user=YES" /usr/local/etc/vsftpd.conf'
chk "/var/ftp/pub 555" '[ "$(stat -f %A /var/ftp/pub)" = "555" ]'
chk "auditd activo" 'service auditd status | grep -qi running'
exit $FAIL
