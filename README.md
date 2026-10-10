# Infraestructura Final — Laboratorio reproducible con Vagrant

Laboratorio académico de 4 VMs (exigido por `PROYECTOFINALNOVIENBRE.pdf`):

| VM | SO | Rol |
|----|----|-----|
| `oracle-web` | Oracle Linux 9 (válido: 7 o mayor) | Hardening + Web HTTP/HTTPS + Wiki SO + Samba |
| `freebsd-ftp` | FreeBSD 14 (válido: 10 o mayor) | Hardening + FTP autenticado + FTP anónimo aislado |
| `windows-dc` | Windows Server 2022 Standard (válido: interpretación `Win16 >` = Server 2016 o superior) | AD DS + DNS + DHCP |
| `windows-client` | Windows 10 | Cliente dominio + DHCP/DNS + Wiki + Samba + FTP |

> **No se sustituye** el DC Windows por Samba AD ni se cambia ningún SO exigido.

## 0. Decisión arquitectónica crítica (leer primero)

`docs/architecture/COMPATIBILITY.md` demuestra que **Windows Server x64 y Windows 10 x64 no corren nativamente en Mac Apple Silicon (ARM64)**. La emulación x86 de Parallels (preview: 1 vCPU, 8 GB máx, sin USB/sonido, sin BSD) no es viable académicamente.

**Estrategia oficial del repo:**

- **Host de laboratorio = x86_64** (PC Windows/Linux o Mac Intel) con VirtualBox o VMware + Vagrant.
- **Mac de presentación = consola de administración y demo**: RDP/SSH/WinRM + `scripts/demo.sh` (no destructivo) + navegador hacia Wiki/Samba/FTP.
- Alternativas documentadas: despliegue completo en host x86 remoto, ejecución híbrida con VPN/SSH, snapshots previos. Emulación local en ARM solo como contingencia degradada, nunca como plan principal.

## 1. Flujo reproducible (10 pasos)

```bash
git clone <repo> && cd infraestructura-final
cp .env.example .env   # completar sin commitear (ver § Secretos)
# Windows (PowerShell): .\scripts\check-prereqs.ps1
# macOS/Linux: bash scripts/check-prereqs.sh
vagrant validate
vagrant box add generic/oracle9 --provider virtualbox        # o según proveedor
vagrant box add generic/freebsd14 --provider virtualbox
vagrant box add gusztavvargadr/windows-server-2022-standard --provider virtualbox
vagrant box add gusztavvargadr/windows-10 --provider virtualbox
# Desactivar DHCP de VirtualBox en la red lab (obligatorio, ver docs/architecture/NETWORK.md):
VBoxManage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0 || true
vagrant up windows-dc --provider=virtualbox --no-parallel
vagrant up oracle-web freebsd-ftp --provider=virtualbox --no-parallel
vagrant up windows-client --provider=virtualbox --no-parallel
bash scripts/validate-lab.sh     # validación no destructiva
bash scripts/demo.sh             # modo demostración académica
```

Comandos útiles: `vagrant status`, `vagrant provision <vm>`, `vagrant ssh oracle-web`, `vagrant powershell windows-dc`, `vagrant halt`, `vagrant snapshot save <vm> <name>`.

> `vagrant ssh` no aplica a Windows (usar WinRM/`vagrant powershell` o RDP). `vagrant powershell` requiere plugin/host Windows; desde macOS usar WinRM/SSH configurado en `00-base.ps1`.

## 2. Secretos

Nunca en Git. Variables requeridas (ver `.env.example`):

- `AD_RECOVERY_PASSWORD` (DSRM), `AD_ADMIN_PASSWORD`, `DOMAIN_USER_PASSWORD`
- `SAMBA_PASSWORD_smbuser1`, `FTP_PASSWORD_ftpuser1`
- `WIKI_ADMIN_PASSWORD`

Los scripts fallan explícitamente si faltan (fail-fast), no usan defaults inseguros.

## 3. Red

- `10.0.2.x` NAT (provisión/internet, eth0).
- `192.168.56.0/24` red lab host-only (eth1):
  - `.10` oracle-web, `.11` freebsd-ftp, `.12` windows-dc (estáticas)
  - `.100–.200` scope DHCP servido **solo** por windows-dc; cliente en DHCP (`auto_config: false`).
- Ver `docs/architecture/NETWORK.md` + diagrama.

## 4. Estructura

```text
Vagrantfile, config/lab.yml, provisioning/{oracle-linux,freebsd,windows-server,windows-client}/
security/, tests/, scripts/, docs/{architecture,hardening,services,presentation}/
evidence/, PLAN.md, PROGRESS.md
```

## 5. Licencias y boxes

- Oracle Linux / FreeBSD: libres. Boxes `generic/*` (Vagrant Cloud, amd64).
- Windows Server/10: requieren licencia Microsoft (evaluación 180 días o licencia académica). Boxes `gusztavvargadr/*` son imágenes de evaluación generalizadas con Sysprep; registrar versión/checksum antes de presentar. Si no hay box pública compatible, construir con Packer (`docs/architecture/BOXES.md`).
- Proveedores: VirtualBox ≥7.0 (recomendado, gratuito) o VMware Fusion/Workstation ≥17.

## 6. Estado del proyecto

Ver `PLAN.md` (plan por fases) y `PROGRESS.md` (pendiente/ejecutado/verificado — sin evidencias inventadas).
