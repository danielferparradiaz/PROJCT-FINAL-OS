# Servicios

## Web/Wiki/Samba (oracle-web)
- httpd + mod_ssl, HTTP→HTTPS redirect, cert autofirmado `oracle-web.lab.local`, headers nosniff/SAMEORIGIN, `httpd_can_network_connect off`.
- DokuWiki (sin BD, ideal lab) en `/var/www/html/wiki` + página inicial SO (procesos/memoria/ficheros/red).
- Samba `academico` (`/srv/samba 2770`, `valid users`, `guest ok no`, `smb encrypt desired`, full_audit, SELinux `samba_share_t`).
- Pruebas: `curl -sk https://192.168.56.10/`, `smbclient -L`, desde cliente `\\oracle-web.lab.local\academico` (positiva con auth, negativa sin auth/guest).

## FTP (freebsd-ftp, vsftpd)
- `anonymous_enable YES` pero `anon_upload/mkdir/other_write NO`, `anon_root /var/ftp`, `pub/` 555; `local_enable`, `chroot_local_user`, `pasv 49152-65534`.
- Pruebas: anon lista `pub/README` y falla al escribir; auth escribe solo en `~/ftp/upload` y no escapa (negativa: `cd /etc` denegado).

## AD/DNS/DHCP (windows-dc, lab.local)
- Bosque `lab.local` (NetBIOS LAB), DNS con forwarders + zona inversa + A records, OUs Lab/Alumnos/Profesores, grupos y usuarios (estudiante1/2, profesor1).
- DHCP scope `.100-.200/24`, router/DNS `.12`, lease 8d, autorizado en AD.
- Pruebas: `Get-ADDomain`, `Resolve-DnsName`, `Get-DhcpServerv4Scope`, lease en cliente, `nltest /dsgetdc`.

## Cliente (windows-client)
- DNS→`.12`, DHCP, join con `estudiante1`, reboot; valida `nltest`, `nslookup`, `Invoke-WebRequest https://oracle-web...`, `net use` samba, `ftp` anon+auth.
