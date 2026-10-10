#!/usr/bin/env bash
# demo.sh — MODO DEMOSTRACIÓN académica, solo lectura. No re-provisiona, no descarga, no cambia estado.
# Uso desde Mac (admin remoto) u host lab: bash scripts/demo.sh
set -u
DC=192.168.56.12; WEB=192.168.56.10; FTP=192.168.56.11
echo "=== DEMO LAB (solo lectura) ==="
echo "[1/9] Estado VMs:"; vagrant status || echo "(si es Mac remota sin Vagrant local: mostrar VirtualBox/VMware del host x86 vía RDP/SSH)"
echo "[2/9] Topología: NAT (provisión) + 192.168.56.0/24 lab (.10 web, .11 ftp, .12 dc, .100-200 dhcp)"
for h in $WEB $FTP $DC; do ping -c1 -W2 $h >/dev/null 2>&1 && echo "ping $h OK" || echo "ping $h FAIL"; done
echo "[3/9] AD/DNS/DHCP (vía WinRM/RDP al DC): Get-ADDomain / Get-DnsServerZone / Get-DhcpServerv4Scope"
echo "[4/9] Cliente dominio: nltest /dsgetdc:lab.local + ipconfig (DHCP .100+, DNS .12)"
echo "[5/9] Wiki:"; curl -sk -o /dev/null -w "HTTPS %{http_code}\n" https://$WEB/ || true
echo "[6/9] Samba: smbclient -L //$WEB -U estudiante1 (password por env, no en pantalla)"
echo "[7/9] FTP:"; curl -s --max-time 8 ftp://anonymous:anonymous@$FTP/pub/ | head -5 || true
echo "[8/9] Hardening: mostrar salida previa de security/*-check (sin re-ejecutar cambios)"
echo "[9/9] Contingencia: si algo falla, usar snapshots (scripts/snapshot.sh) + docs/presentation/CONTINGENCY.md"
echo "=== FIN DEMO (sin modificaciones) ==="
