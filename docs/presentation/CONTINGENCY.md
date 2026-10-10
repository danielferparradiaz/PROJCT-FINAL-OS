# Contingencia

- Sin internet: todo cacheado (boxes + `dnf/pkg` ya instalados); demo no descarga. Llevar `.box` en USB.
- VM no arranca: `vagrant reload`, si no `snapshot restore predemo`; último recurso: video + capturas `evidence/`.
- DHCP pelea: verificar `VBoxManage list dhcpservers` vacío en red lab; `ipconfig /release /renew` en cliente.
- Cert HTTPS: avisar autofirmado y aceptar excepción (no es error).
- Mac ARM sin host x86: RDP al host lab (advertir que necesita red) + video backup. No improvisar emulación x86 en vivo.
- Tiempo: arranque frío ~10-15 min (AD lento); llegar con lab `suspend` y reanudar (`vagrant resume`), no `up` desde cero.
