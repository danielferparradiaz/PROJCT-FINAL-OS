# Matriz de compatibilidad (entregable obligatorio)

Host objetivo del laboratorio: **x86_64**. Boxes del repo son **amd64**.

| Componente | Mac Intel x86_64 (VirtualBox/VMware/Parallels) | Mac Apple Silicon ARM64 (Parallels/VMware/VBox) | Host x86_64 Windows/Linux (recomendado) |
|---|---|---|---|
| oracle-web (Oracle 9, generic/oracle9 amd64) | ✅ nativo | ⚠️ solo emulación x86 (preview Parallels: 1 vCPU, 8GB, inestable; BSD no soportado; sin USB/sonido). No viable académico | ✅ nativo VirtualBox/VMware |
| freebsd-ftp (FreeBSD 14, generic/freebsd14 amd64) | ✅ nativo | ❌ BSD no soportado en emulador Parallels x86; ARM64 requeriría box aarch64 distinta (rompe reproducibilidad x86) | ✅ nativo |
| windows-dc (Server 2022 x64) | ✅ nativo | ❌ no ejecuta x64 nativo; emulación preview 1 vCPU/sin TPM/inestable, updates pueden fallar, AD no soportable | ✅ nativo (requiere licencia/evaluación) |
| windows-client (Win10 x64) | ✅ nativo | ❌ misma limitación; Win11 ARM no sustituye requisito Win10 x64 sin aprobación | ✅ nativo |
| Vagrant provision (shell/WinRM) | ✅ | ⚠️ si la VM no arranca, el provisionador tampoco | ✅ |
| Demo desde macOS | ✅ local | ✅ como consola remota (RDP/SSH/WinRM + browser) hacia host x86 | — |

**Conclusión:** en Apple Silicon el laboratorio completo **no es viable localmente**. Estrategia oficial: host x86 (físico o remoto) + administración/demostración desde Mac. No se propone Windows Server ARM64 ni Samba AD como sustituto sin verificación y aprobación (cambiaría requisito académico).
**Verificar antes del despliegue:** arch (`uname -m`), RAM ≥16GB, disco ≥60GB, macOS/proveedor, conectividad presentación, licencia Windows.
