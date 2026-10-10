# windows-dc 10-ad-dns.ps1 — Promueve a DC lab.local + DNS + OUs/usuarios/grupos.
# Requiere vars env: AD_RECOVERY_PASSWORD, AD_ADMIN_PASSWORD, DOMAIN_USER_PASSWORD
# Idempotente: si ya es DC, solo asegura usuarios/DNS.
$ErrorActionPreference = "Stop"
Write-Host "[10-ad-dns] AD DS + DNS"

$domain = "lab.local"
$netbios = "LAB"
$recovery = $env:AD_RECOVERY_PASSWORD
$adminPass = $env:AD_ADMIN_PASSWORD
$userPass = $env:DOMAIN_USER_PASSWORD
if (-not $recovery -or -not $adminPass -or -not $userPass) {
  Write-Error "Definir AD_RECOVERY_PASSWORD, AD_ADMIN_PASSWORD, DOMAIN_USER_PASSWORD como variables de entorno (no en repo)."
  exit 1
}
$recoverySec = ConvertTo-SecureString $recovery -AsPlainText -Force

# 1. Roles AD + DNS
$feat = Get-WindowsFeature AD-Domain-Services, DNS
if ($feat.Installed -contains $false) {
  Install-WindowsFeature AD-Domain-Services, DNS -IncludeManagementTools
}

# 2. Promover si aún no es DC
$dc = $false
try { $d = Get-ADDomain -ErrorAction Stop; if ($d.DNSRoot -eq $domain) { $dc = $true } } catch { $dc = $false }
if (-not $dc) {
  Write-Host "Promoviendo a nuevo bosque $domain ..."
  Install-ADDSForest -DomainName $domain -DomainNetbiosName $netbios `
    -SafeModeAdministratorPassword $recoverySec -InstallDns:$true `
    -Force:$true -NoRebootOnCompletion:$true
  Write-Host "Bosque creado. Reboot pendiente (provisioner reload-after-ad)."
} else {
  Write-Host "Ya es DC de $domain — omitiendo promoción."
}

# 3. DNS: forwarders + zona inversa lab
# (Tras reboot el servicio DNS ya corre; si aún no, continúa y el siguiente provisioner lo valida)
try {
  Add-DnsServerForwarder -IPAddress "8.8.8.8","1.1.1.1" -ErrorAction SilentlyContinue
  Add-DnsServerPrimaryZone -NetworkID "192.168.56.0/24" -ReplicationScope Forest -ErrorAction SilentlyContinue
  # A records de servidores (idempotentes)
  Add-DnsServerResourceRecordA -ZoneName $domain -Name "oracle-web" -IPv4Address "192.168.56.10" -AllowUpdateAny -ErrorAction SilentlyContinue
  Add-DnsServerResourceRecordA -ZoneName $domain -Name "freebsd-ftp" -IPv4Address "192.168.56.11" -AllowUpdateAny -ErrorAction SilentlyContinue
} catch { Write-Host "DNS aún no listo (normal antes del reboot): $_" }

# 4. OUs, grupos, usuarios (se ejecutan también en re-provision para idempotencia)
# Esperar AD disponible
for ($i=0; $i -lt 12; $i++) {
  try { Get-ADDomain -ErrorAction Stop | Out-Null; break } catch { Start-Sleep 10 }
}
try {
  @("Alumnos","Profesores","AdminsLab") | ForEach-Object {
    if (-not (Get-ADOrganizationalUnit -Filter "Name -eq '$_'" -ErrorAction SilentlyContinue)) {
      # Usar OU raiz Lab
      if (-not (Get-ADOrganizationalUnit -Filter "Name -eq 'Lab'" -ErrorAction SilentlyContinue)) {
        New-ADOrganizationalUnit -Name "Lab" -ProtectedFromAccidentalDeletion $false
      }
      New-ADOrganizationalUnit -Name $_ -Path "OU=Lab,DC=lab,DC=local" -ProtectedFromAccidentalDeletion $false -ErrorAction SilentlyContinue
    }
  }
  $groups = @{ "Alumnos" = "OU=Alumnos,OU=Lab,DC=lab,DC=local"; "Profesores" = "OU=Profesores,OU=Lab,DC=lab,DC=local" }
  foreach ($g in $groups.Keys) {
    if (-not (Get-ADGroup -Filter "Name -eq '$g'" -ErrorAction SilentlyContinue)) {
      New-ADGroup -Name $g -GroupScope Global -GroupCategory Security -Path $groups[$g]
    }
  }
  $users = @(
    @{Name="estudiante1"; OU="OU=Alumnos,OU=Lab,DC=lab,DC=local"; Groups=@("Alumnos")},
    @{Name="estudiante2"; OU="OU=Alumnos,OU=Lab,DC=lab,DC=local"; Groups=@("Alumnos")},
    @{Name="profesor1"; OU="OU=Profesores,OU=Lab,DC=lab,DC=local"; Groups=@("Profesores")}
  )
  $sec = ConvertTo-SecureString $userPass -AsPlainText -Force
  foreach ($u in $users) {
    if (-not (Get-ADUser -Filter "SamAccountName -eq '$($u.Name)'" -ErrorAction SilentlyContinue)) {
      New-ADUser -Name $u.Name -SamAccountName $u.Name -UserPrincipalName "$($u.Name)@$domain" `
        -Path $u.OU -AccountPassword $sec -Enabled $true -PasswordNeverExpires $false `
        -CannotChangePassword $false
    }
    foreach ($gg in $u.Groups) { Add-ADGroupMember -Identity $gg -Members $u.Name -ErrorAction SilentlyContinue }
  }
  # Reset admin password si se provee (solo lab)
  Set-ADAccountPassword -Identity "Administrator" -NewPassword (ConvertTo-SecureString $adminPass -AsPlainText -Force) -Reset
  Write-Host "Usuarios/grupos OK"
} catch { Write-Host "AD aún no disponible para usuarios (reintentará tras reboot o en re-provision): $_" }

Write-Host "[10-ad-dns] OK"
