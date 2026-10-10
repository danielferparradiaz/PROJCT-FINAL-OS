# Guion demo 15 min (modo solo lectura, lab ya aprovisionado)

1. (1') `vagrant status` + topología (NETWORK.md). Mostrar snapshots `predemo`.
2. (2') AD: `Get-ADDomain`, `Get-ADUser -SearchBase OU=Lab...`, `Get-DnsServerZone`, `Get-DhcpServerv4Scope` + lease del cliente.
3. (2') Cliente: `ipconfig /all` (DHCP .100+, DNS .12), `nltest /dsgetdc:lab.local`, login como `estudiante1`.
4. (2') Wiki: browser a `https://oracle-web.lab.local/` (aceptar cert), navegar páginas SO.
5. (2') Samba: `\\oracle-web.lab.local\academico` abre con auth, falla sin auth (negativa).
6. (2') FTP: `ftp://freebsd-ftp/pub` anon lista, intento escritura falla; auth sube a `upload/`.
7. (2') Hardening: salidas previas `oracle-hardening-check` + `freebsd-hardening-check` + `auditpol`.
8. (2') Cierre: `scripts/demo.sh` sin cambios + evidencias en `evidence/`.

Reglas: no `up --provision` ni descargas en vivo; RAM: suspender VMs no usadas si el host sufre; llevar video/capturas backup.
