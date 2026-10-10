# Boxes, licencias y Packer

| VM | Box primaria (amd64) | Proveedores | Licencia |
|----|----------------------|-------------|----------|
| oracle-web | `generic/oracle9` (≥4.3.0) — Oracle Linux 9 cumple "7 o mayor" | virtualbox, vmware, libvirt, parallels | Libre |
| freebsd-ftp | `generic/freebsd14` (≥4.3.0) — cumple "10 o mayor" | virtualbox, vmware, libvirt | Libre (BSD) |
| windows-dc | `gusztavvargadr/windows-server-2022-standard` (≥2601) Desktop Experience | virtualbox, vmware, hyperv, libvirt | Evaluación MS 180d o licencia académica |
| windows-client | `gusztavvargadr/windows-10` | virtualbox, vmware, hyperv | Evaluación o licencia |

- Registrar `vagrant box list -i` + checksum antes de sustentar (las boxes cambian de versión).
- HCP Vagrant termina 31-dic-2026 para `gusztavvargadr/*`: cachear `.box` localmente (`vagrant box add --name ... ./file.box` + `box_url` file://).
- Si no hay box pública compatible: construir con Packer (plantillas `gusztavvargadr/packer` para Windows, `upperstream/packer-templates` o `jhgorse/packer-FreeBSD` para BSD, Oracle ISO oficial). Validar licenciamiento (Windows ISO desde Microsoft Evaluation Center, no redistribuir boxes con licencia).
- Una box x86_64 no se convierte en ARM64: no mezclar archs en el mismo Vagrantfile sin aprobación.
