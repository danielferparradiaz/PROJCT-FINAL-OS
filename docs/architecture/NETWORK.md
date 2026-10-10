# Red del laboratorio

- **NIC1 NAT**: provisión/internet (Vagrant default). No es red académica.
- **NIC2 host-only `192.168.56.0/24`**: red académica aislada, independiente de la red física del aula.
  - Estáticas: `.10` oracle-web, `.11` freebsd-ftp, `.12` windows-dc (DNS `.12`).
  - DHCP: scope `.100–.200` servido **solo** por windows-dc (DNS `.12`, dominio `lab.local`, lease 8d).
  - Cliente: `auto_config: false` en Vagrantfile → NIC adjunta sin IP, Windows obtiene por DHCP del DC.
- **Anti-conflictos (obligatorio)**:
  ```bash
  VBoxManage list dhcpservers
  VBoxManage dhcpserver remove --netname HostInterfaceNetworking-vboxnet0
  # o: VBoxManage dhcpserver modify --netname ... --disable
  ```
  Nunca exponer el DHCP lab a red física (host-only, sin bridge).
- **DNS**: DC es autoritativo `lab.local` + forwarders 8.8.8.8/1.1.1.1; A records oracle-web/freebsd-ftp; cliente y servidores apuntan a `.12`.
- **Firewall**: oracle firewalld (22/80/443 + samba solo lab); freebsd pf (22/21+pasivo solo lab); Windows firewall perfiles activos + RDP/WinRM solo lab.
- **Validar antes de apps**: `ping`, `nslookup lab.local 192.168.56.12`, `ipconfig /all` (DHCP server .12), `curl https://192.168.56.10/`.
