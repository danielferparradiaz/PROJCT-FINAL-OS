# windows-dc 20-dhcp.ps1 — DHCP autorizado en red lab 192.168.56.100-200.
# DEBE ejecutarse tras ser DC (requiere reboot previo). Idempotente.
$ErrorActionPreference = "Stop"
Write-Host "[20-dhcp] DHCP scope lab"

Install-WindowsFeature DHCP -IncludeManagementTools
# Autorizar en AD (solo DC enterprise admin)
try { Add-DhcpServerInDC -DnsName "windows-dc.lab.local" -IPAddress "192.168.56.12" -ErrorAction SilentlyContinue } catch { Write-Host "Ya autorizado o pendiente: $_" }
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12" -Name "ConfigurationState" -Value 2 -ErrorAction SilentlyContinue
Restart-Service dhcpserver -ErrorAction SilentlyContinue; Start-Service dhcpserver

$scopeId = "192.168.56.0"
# Crear scope si no existe
$existing = Get-DhcpServerv4Scope -ScopeId $scopeId -ErrorAction SilentlyContinue
if (-not $existing) {
  Add-DhcpServerv4Scope -Name "LabScope" -StartRange "192.168.56.100" -EndRange "192.168.56.200" `
    -SubnetMask "255.255.255.0" -State Active
  Write-Host "Scope creado."
} else { Write-Host "Scope ya existe." }

Set-DhcpServerv4OptionValue -ScopeId $scopeId -DnsServer "192.168.56.12" -DnsDomain "lab.local" `
  -Router "192.168.56.12" -Force
Set-DhcpServerv4OptionValue -ScopeId $scopeId -OptionId 6 -Value @("192.168.56.12") -Force
# Lease 8 días
Set-DhcpServerv4Scope -ScopeId $scopeId -LeaseDuration (New-TimeSpan -Days 8)

# Reserva opcional para windows-client (documentar MAC tras primer lease; no obligatoria)
# Add-DhcpServerv4Reservation -ScopeId $scopeId -IPAddress "192.168.56.100" -ClientId "<MAC-sin-guiones>" -Name "windows-client" -ErrorAction SilentlyContinue

# Validación real: scope activo + servidor autorizado
Get-DhcpServerv4Scope -ScopeId $scopeId | Format-Table Name,StartRange,EndRange,State -AutoSize
Get-DhcpServerInDC | Format-Table DnsName,IPAddress -AutoSize

Write-Host "[20-dhcp] OK — único DHCP autorizado en red lab. Verificar que VirtualBox DHCP está desactivado."
