#!/usr/bin/env sh
# freebsd-ftp hardening base — idempotente (sh POSIX, no bashisms).
set -eu
echo "[00-base] FreeBSD hardening base"

# 1. Actualizar sistema + paquetes
freebsd-update fetch install || true
pkg update -f
pkg upgrade -y || true

# 2. Usuario admin (sin password en repo)
pw user show opsadmin >/dev/null 2>&1 || pw useradd opsadmin -m -s /bin/sh -G wheel
# Bloquear root SSH, solo claves
cp -n /etc/ssh/sshd_config /etc/ssh/sshd_config.bak || true
sed -i '' -E 's/^#?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i '' -E 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
sed -i '' -E 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/' /etc/ssh/sshd_config
sed -i '' -E 's/^#?X11Forwarding.*/X11Forwarding no/' /etc/ssh/sshd_config
grep -q "Banner /etc/issue.net" /etc/ssh/sshd_config || echo "Banner /etc/issue.net" >> /etc/ssh/sshd_config
echo "Acceso autorizado - laboratorio academico. Actividad registrada." > /etc/issue.net
service sshd restart

# 3. PF firewall: permitir 22,21 + pasivo 49152-65534 solo desde red lab, resto bloqueado
cat >/etc/pf.conf <<'EOF'
labnet = "192.168.56.0/24"
set skip on lo
block in all
pass out all keep state
pass in on { em0 vtnet0 } proto tcp from $labnet to any port { 22 21 } keep state
pass in on { em0 vtnet0 } proto tcp from $labnet to any port 49152:65534 keep state
EOF
pfctl -nf /etc/pf.conf && echo 'pf_enable="YES"' >> /etc/rc.conf || true
# evitar duplicados
grep -q 'pf_enable="YES"' /etc/rc.conf || echo 'pf_enable="YES"' >> /etc/rc.conf
grep -q 'pflog_enable="YES"' /etc/rc.conf || echo 'pflog_enable="YES"' >> /etc/rc.conf
service pf restart || pfctl -e || true

# 4. Servicios innecesarios: deshabilitar sendmail, rpcbind si no se usan
sysrc sendmail_enable="NO" sendmail_submit_enable="NO" sendmail_outbound_enable="NO" sendmail_msp_queue_enable="NO" || true
sysrc rpcbind_enable="NO" || true

# 5. Auditoría: auditd + syslog para auth/ftp
sysrc auditd_enable="YES" || true
service auditd start || true
# login records + ftp logging se configuran en 10-ftp.sh

# 6. Actualizaciones: freebsd-update cron semanal (seguridad)
grep -q "freebsd-update cron" /etc/crontab || echo "0 3 * * 0 root /usr/sbin/freebsd-update cron" >> /etc/crontab

# 7. Sudo con log
pkg install -y sudo || true
echo "Defaults logfile=/var/log/sudo.log" > /usr/local/etc/sudoers.d/lab-logging
chmod 440 /usr/local/etc/sudoers.d/lab-logging
pw groupmod wheel -m opsadmin || pw group mod wheel -m opsadmin || true

echo "[00-base] OK — verificar con security/freebsd-hardening-check.sh"
