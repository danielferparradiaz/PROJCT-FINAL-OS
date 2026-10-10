# Arquitectura

- Orquestación: Vagrant multi-machine (`oracle-web`, `freebsd-ftp`, `windows-dc`, `windows-client`), `config/lab.yml` centraliza IPs/boxes/recursos.
- Proveedor primario: VirtualBox ≥7.0 (gratuito, host-only). Alternativa: VMware Fusion/Workstation ≥17.
- Recursos: dc 2vCPU/4GB, client 2vCPU/3GB, oracle 2vCPU/2GB, freebsd 1vCPU/1GB (total ~10GB → host 16GB).
- Provisión por etapas idempotentes: shell (Linux/BSD) + PowerShell+reload (Windows, 2 reboots previstos para AD/join).
- Seguridad: sin secretos en repo (env), firewall/pf, SELinux, auditd/auditpol, chroot FTP, SMB sin guest.
- Validación: `tests/test-services.sh` + `security/*-check` + `scripts/validate-lab.sh` (resultados reales).
- Presentación: `scripts/demo.sh` solo lectura + snapshots + RDP/SSH desde Mac.

```text
[NAT 10.0.2.x provisión] ── todas las VMs (eth0)
[Red lab 192.168.56.0/24 host-only (eth1)]
  .10 oracle-web (http/https/smb) ─ .11 freebsd-ftp (ftp) ─ .12 windows-dc (ad/dns/dhcp) ─ .100-200 windows-client (dhcp)
[Mac presentación] --RDP/WinRM/SSH/HTTPS--> [host x86 lab]
```
