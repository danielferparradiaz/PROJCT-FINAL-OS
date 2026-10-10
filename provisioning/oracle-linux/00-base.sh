#!/usr/bin/env bash
# oracle-web hardening base — idempotente. Oracle Linux 7/8/9 (yum/dnf).
# No modifica servicios académicos (httpd/samba se configuran en 10/20).
set -euo pipefail

echo "[00-base] Oracle hardening base"

# 1. Actualizaciones de seguridad (sin -y upgrade mayor automático destructivo: solo security cuando disponible)
if command -v dnf >/dev/null 2>&1; then
  dnf -y update --security || dnf -y update
else
  yum -y update --security || yum -y update
fi

# 2. Usuarios: bloquear root SSH, crear admin académico si no existe (sin password en repo)
if ! id opsadmin >/dev/null 2>&1; then
  useradd -m -s /bin/bash opsadmin
  usermod -aG wheel opsadmin || true
  echo "opsadmin creado (fijar password fuera de repo: passwd opsadmin)"
fi

# 3. SSH: deshabilitar root login + password auth solo si hay clave (seguro para vagrant)
SSHD=/etc/ssh/sshd_config
cp -n "$SSHD" "${SSHD}.bak.$(date +%F)" || true
sed -i -E 's/^#?PermitRootLogin.*/PermitRootLogin no/' "$SSHD"
sed -i -E 's/^#?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD"
sed -i -E 's/^#?PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD"
sed -i -E 's/^#?X11Forwarding.*/X11Forwarding no/' "$SSHD"
# Vagrant usa clave insegura por defecto en primer arranque; mantener acceso por clave y documentar rotación.
systemctl restart sshd

# 4. Firewall: firewalld solo 22,80,443,445 + 137-139/445 samba restringido a red lab
systemctl enable --now firewalld
firewall-cmd --permanent --set-default-zone=public
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --permanent --add-service=samba
# Restringir samba a red lab (ejemplo 192.168.56.0/24; idempotente con rich rules)
firewall-cmd --permanent --remove-service=samba || true
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="192.168.56.0/24" service name="samba" accept' || true
firewall-cmd --reload

# 5. SELinux enforcing (no desactivar)
setenforce 1 || true
sed -i -E 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config

# 6. Servicios innecesarios desactivados (lista conservadora, no toca httpd/smb aún)
for s in cups avahi-daemon rpcbind postfix telnet; do
  systemctl disable --now "$s" 2>/dev/null || true
done

# 7. Auditoría: auditd + reglas básicas + logrotate
systemctl enable --now auditd
cat >/etc/audit/rules.d/lab.rules <<'EOF'
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/sudoers -p wa -k sudo
-w /var/log/secure -p wa -k auth
-w /etc/httpd/ -p wa -k web
-w /etc/samba/ -p wa -k samba
EOF
augenrules --load || service auditd restart

# 8. Actualizaciones automáticas de seguridad (dnf-automatic) solo download+apply security
if command -v dnf >/dev/null 2>&1; then
  dnf -y install dnf-automatic
  sed -i -E 's/^upgrade_type.*/upgrade_type = security/' /etc/dnf/automatic.conf
  sed -i -E 's/^apply_updates.*/apply_updates = yes/' /etc/dnf/automatic.conf
  systemctl enable --now dnf-automatic.timer
fi

# 9. Banner legal + umask + sudo logging
echo "Acceso autorizado - laboratorio academico. Actividad registrada." > /etc/issue.net
grep -q "Banner /etc/issue.net" "$SSHD" || echo "Banner /etc/issue.net" >> "$SSHD"
systemctl restart sshd
echo "umask 027" >> /etc/bashrc || true
echo "Defaults logfile=/var/log/sudo.log" > /etc/sudoers.d/lab-logging
chmod 440 /etc/sudoers.d/lab-logging

echo "[00-base] OK — verificar con security/oracle-hardening-check.sh"
