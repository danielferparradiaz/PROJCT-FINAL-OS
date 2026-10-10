# PLAN.md — Plan de implementación por etapas

Fuente: `PROYECTOFINALNOVIENBRE.pdf` (resumen verificado en PROGRESS.md §0).

## Fase 0 — Análisis y arquitectura (actual)

- [x] Extraer requisitos del PDF (2 partes: 15% hardening + 20% servicios).
- [x] Interpretar `Win16 >` como Windows Server 2016 o superior → proponer 2022 (alternativa 2019) con aprobación docente.
- [x] Matriz compatibilidad Intel vs Apple Silicon (`docs/architecture/COMPATIBILITY.md`).
- [x] Topología de red aislada + estrategia DHCP/DNS (`docs/architecture/NETWORK.md`).
- [x] Vagrantfile multi-machine + `config/lab.yml` centralizado.
- [ ] Confirmar con docente: versión exacta Server (2016/2019/2022), dominio `lab.local` aceptado, Wiki (DokuWiki sin BD) aceptada, FTP server (vsftpd) aceptado.
- [ ] Confirmar Mac de presentación: Intel o Apple Silicon, RAM, disco, macOS, proveedor, internet.

## Fase 1 — Base y hardening (Parte 1, 15%)

1. `oracle-web`: `00-base.sh` (update, usuarios, sshd, firewalld, auditd, SELinux, servicios mínimos).
2. `freebsd-ftp`: `00-base.sh` (pkg, usuarios, sshd, pf, audit, servicios mínimos).
3. Validar con `security/*-check.sh` + `tests/test-hardening.sh`. Evidencia en `evidence/`.

## Fase 2 — Servicios Linux/BSD (Parte 2, 20%)

4. `oracle-web`: `10-web-wiki.sh` (httpd + TLS autofirmado + DokuWiki SO) y `20-samba.sh` (share `academico`, permisos, SELinux, firewall).
5. `freebsd-ftp`: `10-ftp.sh` (vsftpd: chroot, anónimo solo-lectura `/var/ftp/pub`, autenticado aislado).
6. Pruebas positivas/negativas (`tests/test-services.sh`).

## Fase 3 — Windows (Parte 2, 20%)

7. `windows-dc`: `00-base.ps1` → reload → `10-ad-dns.ps1` (bosque `lab.local`, DNS, OUs/usuarios/grupos) → reload → `20-dhcp.ps1` (scope .100-.200, DNS .12).
8. `windows-client`: `00-join-domain.ps1` (DNS→.12, join, reboot) → `10-validate.ps1` (nltest, nslookup, wiki, smb, ftp).
9. Manejo explícito de reboots (provisioner `reload`, máx 2 reboots por VM).

## Fase 4 — Integración y aceptación

10. `scripts/validate-lab.sh`: ping, DNS, DHCP lease, curl wiki http/https, smbclient, ftp anónimo/autenticado, AD.
11. Registrar evidencias reales (capturas, logs anonimizados) en `evidence/`. No inventar resultados.

## Fase 5 — Sustentación macOS

12. `scripts/demo.sh` (solo lectura), snapshots previos, `docs/presentation/DEMO-GUIDE.md` (guion 15 min) + `CONTINGENCY.md`.
13. Ensayo: arranque en frío cronometrado, `vagrant suspend/resume`, plan sin internet.

## Riesgos y bloqueadores

| Riesgo | Mitigación |
|--------|------------|
| Apple Silicon no corre Win x64 nativo | Host x86 + control remoto desde Mac (estrategia oficial) |
| DHCP VirtualBox compite con DC | Desactivar `dhcpserver` en red lab; `auto_config:false` en cliente |
| Boxes Windows sin licencia/evaluación expirada | Licencia académica/MSDN + snapshot + documentar build Packer |
| AD requiere 2 reboots | Provisioners separados + `reload`; nunca un solo `up` monolítico |
| RAM total ~10 GB | Host ≥16 GB; arranque por orden; suspender VMs no usadas en demo |
| Internet inestable en presentación | Boxes + paquetes cacheados; demo sin descargas; snapshots |

## Primer paso concreto

1. Docente aprueba Server 2022 + dominio + vsftpd/DokuWiki.
2. En host x86: instalar Vagrant ≥2.4 + VirtualBox ≥7.0, ejecutar `scripts/check-prereqs.*`, `vagrant validate`, `vagrant up windows-dc --no-parallel`.
