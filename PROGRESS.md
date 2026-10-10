# PROGRESS.md — Pendiente / Ejecutado / Verificado

> Regla: no afirmar que algo funciona sin prueba. Sin evidencias inventadas.

## §0 Requisitos extraídos del PDF (verificado por lectura directa)

- **Parte 1 (15%)**: Aseguramiento. VMs Oracle Linux 7x o mayor + FreeBSD 10 o mayor. Entregables: máquinas aseguradas + documentación. Grupo 4. Entrega última semana de clase.
- **Parte 2 (20%)**: Implementación servicios. Oracle (WebServer, Wiki de SO, Samba con Win10). FreeBSD (FTP nombrado y anonymous). Win10 + Win16> (cliente de los dos anteriores, visualizan wiki y se loguean, conectado a dominio, servidor DHCP). Entregables: máquinas funcionando + documentación. Grupo 3. Fecha parcial.
- Diagrama: Domain Controller Win16> + DHCP; Wiki+Samba; Cliente Win10; FTP nombrado+anonymous.
- **Interpretación pendiente de aprobación**: `Win16 >` = Windows Server 2016 o superior. Propuesta: Server 2022 Standard (alternativa 2019).

## Pendiente

- [ ] Aprobación docente de versiones (Server 2022, Oracle 9, FreeBSD 14, DokuWiki, vsftpd).
- [ ] Datos Mac presentación (arch, RAM, disco, macOS, proveedor, red).
- [ ] Instalación Vagrant+VirtualBox en host x86 (este host actual no los tiene — verificado 2026-10-10).
- [ ] `vagrant validate`, `vagrant up` por orden, provisioners, tests, evidencias.

## Ejecutado (no verificado en ejecución)

- [x] Estructura repo + Vagrantfile + lab.yml + scripts base + docs arquitectura (2026-10-10, sin `vagrant` disponible para validar).

## Verificado

- (vacío — se llenará con salidas reales de `validate-lab.sh`, `test-*.sh`, capturas en `evidence/`).

## Bitácora

- 2026-10-10: Creado esqueleto reproducible. Host dev actual sin Vagrant/VirtualBox. Estrategia Apple Silicon documentada (host x86 + control desde Mac).
