#!/usr/bin/env bash
# oracle-web: httpd + TLS + DokuWiki (wiki de sistemas operativos, sin BD).
# Idempotente. Requiere 00-base.sh previo.
set -euo pipefail
echo "[10-web-wiki] Instalando web + wiki"

PKG="httpd mod_ssl php php-gd dokuwiki"
if command -v dnf >/dev/null 2>&1; then dnf -y install $PKG || dnf -y install httpd mod_ssl php php-gd
else yum -y install $PKG || yum -y install httpd mod_ssl php php-gd; fi

# Si dokuwiki no está en repos base, descargar release oficial (pinneado, verificar checksum manualmente)
if [ ! -d /usr/share/dokuwiki ] && [ ! -d /var/www/html/wiki ]; then
  echo "DokuWiki no encontrada en repos; descargando release estable..."
  DOKU_VER="2024-02-06a"  # actualizar + registrar checksum en docs/services/WEB-WIKI-SAMBA.md
  curl -fsSL -o /tmp/dokuwiki.tgz "https://download.dokuwiki.org/src/dokuwiki/dokuwiki-${DOKU_VER}.tgz"
  mkdir -p /var/www/html/wiki
  tar -xzf /tmp/dokuwiki.tgz -C /var/www/html/wiki --strip-components=1
  chown -R apache:apache /var/www/html/wiki
fi
# Si vino por paquete, enlazar
[ -d /usr/share/dokuwiki ] && [ ! -e /var/www/html/wiki ] && ln -sfn /usr/share/dokuwiki /var/www/html/wiki || true
chown -R apache:apache /var/www/html/wiki 2>/dev/null || true

# Cert autofirmado (para laboratorio; en producción usar CA interna del dominio)
mkdir -p /etc/pki/tls/certs /etc/pki/tls/private
if [ ! -f /etc/pki/tls/certs/wiki-lab.crt ]; then
  openssl req -x509 -nodes -days 825 -newkey rsa:2048 \
    -keyout /etc/pki/tls/private/wiki-lab.key \
    -out /etc/pki/tls/certs/wiki-lab.crt \
    -subj "/CN=oracle-web.lab.local/O=LabAcademico"
  chmod 600 /etc/pki/tls/private/wiki-lab.key
fi

cat >/etc/httpd/conf.d/wiki-lab.conf <<'EOF'
<VirtualHost *:80>
  ServerName oracle-web.lab.local
  Redirect permanent / https://oracle-web.lab.local/
</VirtualHost>
<VirtualHost *:443>
  ServerName oracle-web.lab.local
  DocumentRoot /var/www/html/wiki
  SSLEngine on
  SSLCertificateFile /etc/pki/tls/certs/wiki-lab.crt
  SSLCertificateKeyFile /etc/pki/tls/private/wiki-lab.key
  # Cabeceras de seguridad
  Header always set X-Content-Type-Options nosniff
  Header always set X-Frame-Options SAMEORIGIN
  Header always set Referrer-Policy no-referrer
  <Directory /var/www/html/wiki>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>
</VirtualHost>
EOF

# Wiki inicial: página de SO (contenido académico mínimo, ampliable por alumnos)
mkdir -p /var/www/html/wiki/data/pages 2>/dev/null || true
cat >/var/www/html/wiki/data/pages/start.txt 2>/dev/null <<'EOF' || true
====== Wiki de Sistemas Operativos ======
Laboratorio: Oracle Linux (web/samba) + FreeBSD (ftp) + Windows Server (AD/DNS/DHCP) + Win10.

 * [[procesos|Procesos y planificación]]
 * [[memoria|Gestión de memoria]]
 * [[ficheros|Sistemas de ficheros y permisos]]
 * [[red|Redes y servicios (DNS/DHCP/SMB/FTP)]]
EOF
chown -R apache:apache /var/www/html/wiki 2>/dev/null || true

# SELinux contextos + firewall ya abierto en 00-base (80/443)
restorecon -Rv /var/www/html/wiki 2>/dev/null || true
setsebool -P httpd_can_network_connect 0
setsebool -P httpd_enable_homedirs 0

systemctl enable --now httpd
# Validación real (no solo exit 0): HTTP redirige, HTTPS 200
curl -sk -o /dev/null -w "%{http_code}\n" http://localhost/ | grep -q "301" && echo "HTTP redirect OK"
curl -sk -o /dev/null -w "%{http_code}\n" https://localhost/ | grep -Eq "200|302" && echo "HTTPS OK"

echo "[10-web-wiki] OK — https://192.168.56.10/ (aceptar cert autofirmado en demo)"
