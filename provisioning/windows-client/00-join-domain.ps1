# windows-client 00-join-domain.ps1 — Apunta DNS al DC y une al dominio lab.local.
# Requiere env DOMAIN_USER_PASSWORD (para validar) y que windows-dc ya sirva DNS/DHCP.
$ErrorActionPreference = "Stop"
Write-Host "[join] Uniendo a lab.local"

$dcIp = "192.168.56.12"
$domain = "lab.local"
$user = "estudiante1"
$pass = $env:DOMAIN_USER_PASSWORD
if (-not $pass) { Write-Error "Definir DOMAIN_USER_PASSWORD"; exit 1 }
$sec = ConvertTo-SecureString $pass -AsPlainText -Force
$cred = New-Object PSCredential("$domain\$user", $sec)

# 1. DNS -> DC en el adaptador lab (el que tiene 192.168.56.x o DHCP)
$adapters = Get-NetAdapter | Where-Object Status -eq "Up"
foreach ($a in $adapters) {
  # Fijar DNS al DC en todos los adaptadores físicos activos (simple y robusto en lab)
  Set-DnsClientServerAddress -InterfaceIndex $a.ifIndex -ServerAddresses @($dcIp) -ErrorAction SilentlyContinue
}
ipconfig /flushdns
# Esperar DNS del dominio
for ($i=0; $i -lt 18; $i++) {
  try { Resolve-DnsName $domain -Server $dcIp -ErrorAction Stop | Out-Null; Write-Host "DNS OK"; break }
  catch { Write-Host "Esperando DNS... ($i)"; Start-Sleep 10 }
  if ($i -eq 17) { Write-Error "DNS $domain no resuelve vía $dcIp"; exit 1 }
}

# 2. Unir si aún no está en dominio
$cs = Get-WmiObject Win32_ComputerSystem
if ($cs.Domain -ne $domain) {
  # Forzar DHCP en adaptador lab antes de unir (asegura IP del scope .100-.200)
  Get-NetAdapter | Where-Object Status -eq "Up" | ForEach-Object {
    Set-NetIPInterface -InterfaceIndex $_.ifIndex -Dhcp Enabled -ErrorAction SilentlyContinue
    Set-DnsClient -InterfaceIndex $_.ifIndex -RegisterThisConnectionsAddress $true -ErrorAction SilentlyContinue
  }
  ipconfig /renew
  Add-Computer -DomainName $domain -Credential $cred -Force -Options JoinWithNewName,AccountCreate
  Write-Host "Unido. Reboot pendiente (provisioner reload-after-join)."
} else {
  Write-Host "Ya en dominio $domain"
}
