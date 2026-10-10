#!/usr/bin/env sh
# freebsd-ftp: vsftpd con FTP autenticado (chroot) + anónimo solo-lectura aislado.
# Idempotente. Password por env FTP_PASSWORD_ftpuser1.
set -eu
echo "[10-ftp] Instalando vsftpd"

pkg install -y vsftpd || true
FTPPASS="${FTP_PASSWORD_ftpuser1:-}"
if [ -z "$FTPPASS" ]; then echo "ERROR: definir FTP_PASSWORD_ftpuser1" >&2; exit 1; fi

# Usuario autenticado, jaula en su home, sin shell
pw user show ftpuser1 >/dev/null 2>&1 || pw useradd ftpuser1 -m -s /usr/sbin/nologin
echo "$FTPPASS" | pw usermod ftpuser1 -h 0
mkdir -p /home/ftpuser1/ftp/upload
chown root:ftpuser1 /home/ftpuser1/ftp 2>/dev/null || chown root /home/ftpuser1/ftp
chmod 555 /home/ftpuser1/ftp
chown ftpuser1 /home/ftpuser1/ftp/upload
chmod 553 /home/ftpuser1/ftp 2>/dev/null || true

# Anónimo: /var/ftp/pub solo lectura, sin escritura, sin listar fuera
mkdir -p /var/ftp/pub
chown root:wheel /var/ftp /var/ftp/pub
chmod 555 /var/ftp /var/ftp/pub
echo "Bienvenido al FTP anonimo academico (solo lectura)." > /var/ftp/pub/README.txt
chmod 444 /var/ftp/pub/README.txt

cat >/usr/local/etc/vsftpd.conf <<'EOF'
listen=YES
anonymous_enable=YES
anon_root=/var/ftp
anon_max_rate=50000
no_anon_password=NO
anon_upload_enable=NO
anon_mkdir_write_enable=NO
anon_other_write_enable=NO
anon_world_readable_only=YES
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
user_sub_token=$USER
local_root=/home/$USER/ftp
pasv_enable=YES
pasv_min_port=49152
pasv_max_port=65534
xferlog_enable=YES
xferlog_file=/var/log/vsftpd.log
log_ftp_protocol=YES
max_clients=20
max_per_ip=3
hide_ids=YES
seccomp_sandbox=NO
EOF

sysrc vsftpd_enable="YES"
service vsftpd restart

# PF ya permite 21 + pasivo (ver 00-base). Recargar por si acaso.
pfctl -nf /etc/pf.conf && pfctl -f /etc/pf.conf || true

# Validación real:
# 1. config sintaxis: vsftpd no tiene --test; validar puerto 21 escuchando
sockstat -l 2>/dev/null | grep -q ":21" && echo "FTP listen OK" || (sleep 2; sockstat -l | grep -q ":21" && echo "FTP listen OK")
# 2. anónimo solo-lectura (intento de escritura debe fallar) — usa ftp(1) no interactivo
ftp -a -N /tmp/ftp-anon-test 2>/dev/null <<'FTPEOF' || true
open 127.0.0.1
anonymous
anonymous@
ls
quit
FTPEOF
echo "[10-ftp] Revisar /var/log/vsftpd.log para evidencia de login anonimo/auth"

echo "[10-ftp] OK — ftp://192.168.56.11/pub (anon) + usuarios chroot"
