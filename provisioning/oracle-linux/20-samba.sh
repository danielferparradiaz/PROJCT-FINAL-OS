#!/usr/bin/env bash
# oracle-web: Samba con share académico accesible desde Win10 del dominio.
# Idempotente. Passwords por variables de entorno (no en repo).
# Requiere: SMB_PASSWORD_smbuser1 (o SAMBA_PASSWORD_smbuser1) exportada en provision.
set -euo pipefail
echo "[20-samba] Instalando samba"

if command -v dnf >/dev/null 2>&1; then dnf -y install samba samba-client cifs-utils
else yum -y install samba samba-client cifs-utils; fi

# Usuario samba (sistema + smbpasswd). No falla si ya existe.
id smbuser1 >/dev/null 2>&1 || useradd -M -s /sbin/nologin smbuser1
SMBPASS="${SMB_PASSWORD_smbuser1:-${SAMBA_PASSWORD_smbuser1:-}}"
if [ -z "$SMBPASS" ]; then echo "ERROR: definir SMB_PASSWORD_smbuser1 como variable de entorno" >&2; exit 1; fi
echo -e "${SMBPASS}\n${SMBPASS}" | smbpasswd -a -s smbuser1
smbpasswd -e smbuser1

mkdir -p /srv/samba/academico
chown root:"Domain Users" /srv/samba/academico 2>/dev/null || chown root:smbuser1 /srv/samba/academico
chmod 2770 /srv/samba/academico
# ACL: smbuser1 rwx, grupo lectura según necesidad académica
setfacl -m u:smbuser1:rwx /srv/samba/academico || true

cat >/etc/samba/smb.conf <<'EOF'
[global]
  workgroup = LAB
  realm = LAB.LOCAL
  server string = oracle-web academico
  security = user
  map to guest = never
  guest ok = no
  smb encrypt = desired
  log file = /var/log/samba/log.%m
  max log size = 1000
  logging = file
  # Auditoría de accesos
  full audit:prefix = %u|%I|%S
  full audit:success = mkdir rmdir read pread write pwrite rename unlink
  full audit:failure = none
  vfs objects = full_audit
[academico]
  path = /srv/samba/academico
  browseable = yes
  writable = yes
  valid users = smbuser1 @wheel
  create mask = 0660
  directory mask = 2770
  guest ok = no
EOF

testparm -s  # valida sintaxis real
semanage fcontext -a -t samba_share_t "/srv/samba/academico(/.*)?" 2>/dev/null || true
restorecon -Rv /srv/samba/academico
setsebool -P samba_enable_home_dirs off
setsebool -P smbd_anon_write 0

systemctl enable --now smb nmb
firewall-cmd --reload || true
# Validación real: smbclient lista share con credenciales (password por env, no en log)
export PASSWD="$SMBPASS"
smbclient -L localhost -U smbuser1%"$SMBPASS" | grep -qi academico && echo "Samba share OK"
unset PASSWD SMBPASS

echo "[20-samba] OK — \\\\192.168.56.10\\academico (requiere auth; sin guest)"
