# windows-dc 00-base.ps1 — Base + firewall + auditoría (requiere reboot posterior vía provisioner reload).
# Idempotente. No instala AD aquí.
$ErrorActionPreference = "Stop"
Write-Host "[00-base] Windows Server base"

# 1. Hostname ya lo pone Vagrant; asegurar zona horaria + updates manuales (no auto-reboot en demo)
# Desactivar shepherds innecesarios no críticos (conservador)
$servicesToDisable = @("Spooler","Fax")
foreach ($s in $servicesToDisable) {
  $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
  if ($svc) { Stop-Service $s -Force -ErrorAction SilentlyContinue; Set-Service $s -StartupType Disabled }
}

# 2. Firewall: baseline — bloquear inbound salvo WinRM (provisión), luego AD/DNS/DHCP abren lo suyo
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
# WinRM solo desde red lab (provisión). Se endurece más tras aprovisionar (ver docs/hardening/WINDOWS.md)
Set-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" -RemoteAddress "192.168.56.0/24" -ErrorAction SilentlyContinue
# RDP solo lab (para demo/admin)
Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
Set-NetFirewallRule -DisplayGroup "Remote Desktop" -RemoteAddress "192.168.56.0/24" -ErrorAction SilentlyContinue

# 3. Auditoría avanzada (logon, cambios cuenta, acceso objetos)
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Account Logon" /success:enable /failure:enable
auditpol /set /category:"Account Management" /success:enable /failure:enable
auditpol /set /category:"Policy Change" /success:enable /failure:enable

# 4. Contraseña/Lockout baseline (se refuerza con GPO tras promover a DC)
# En workgroup previo a DC: política local
net accounts /minpwlen:10 /maxpwage:60 /minpwage:1 /lockoutthreshold:5 /lockoutwindow:30 /lockoutduration:30

# 5. WinRM: servicio automático, sin auth básica insegura permanente
Set-Service WinRM -StartupType Automatic
winrm quickconfig -quiet -force
winrm set winrm/config/service/auth '@{Basic="false"; Negotiate="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="false"}'

# 6. IP estática ya la pone Vagrant (192.168.56.12). Fijar DNS a loopback provisional (tras AD será 127.0.0.1)
$labIp = "192.168.56.12"
$adapters = Get-NetAdapter | Where-Object Status -eq "Up"
foreach ($a in $adapters) {
  $cfg = Get-NetIPConfiguration -InterfaceIndex $a.ifIndex -ErrorAction SilentlyContinue
  if ($cfg.IPv4Address.IPAddress -eq $labIp) {
    Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @("127.0.0.1","8.8.8.8")
    Write-Host "DNS provisional en $($a.Name)"
  }
}

Write-Host "[00-base] OK — reboot pendiente (provisioner reload)"
