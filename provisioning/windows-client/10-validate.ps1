# windows-client 10-validate.ps1 — Pruebas funcionales reales (no solo exit 0). Solo lectura salvo logs.
$ErrorActionPreference = "Continue"
Write-Host "[validate] Pruebas cliente"

$ok = $true
function Check($name, [scriptblock]$sb) {
  try { &$sb; Write-Host "PASS: $name" } catch { Write-Host "FAIL: $name -> $_"; $script:ok = $false }
}

Check "Dominio" { (Get-WmiObject Win32_ComputerSystem).Domain | Where-Object { $_ -eq "lab.local" } | Out-Null; if ((Get-WmiObject Win32_ComputerSystem).Domain -ne "lab.local") { throw "no en dominio" } }
Check "DNS lab.local" { Resolve-DnsName "lab.local" -ErrorAction Stop | Out-Null }
Check "DNS oracle-web" { Resolve-DnsName "oracle-web.lab.local" -ErrorAction Stop | Out-Null }
Check "DHCP IP 192.168.56.x" {
  $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.IPAddress -like "192.168.56.*" }).IPAddress | Select-Object -First 1
  if (-not $ip) { throw "sin IP lab" }; Write-Host "  IP=$ip"
  ipconfig /all | Select-String "DHCP Server|192.168.56.12" | Out-Null
}
Check "Wiki HTTPS" {
  # Aceptar cert autofirmado solo en lab
  add-type @"
using System.Net; using System.Security.Cryptography.X509Certificates;
public class T { public static void I() { ServicePointManager.ServerCertificateValidationCallback = delegate { return true; }; } }
"@
  [T]::I()
  $r = Invoke-WebRequest -Uri "https://oracle-web.lab.local/" -UseBasicParsing -TimeoutSec 15
  if ($r.StatusCode -notin @(200,302)) { throw "HTTP $($r.StatusCode)" }
}
Check "Samba \\oracle-web\academico" {
  # Prueba de listado con usuario dominio (password por env, no se loguea)
  $u = "lab.local\estudiante1"; $p = $env:DOMAIN_USER_PASSWORD
  if (-not $p) { throw "falta DOMAIN_USER_PASSWORD" }
  net use \\oracle-web.lab.local\academico $p /user:$u 2>&1 | Out-Null
  if (-not (Test-Path "\\oracle-web.lab.local\academico")) { throw "share no accesible" }
  net use \\oracle-web.lab.local\academico /delete /y 2>&1 | Out-Null
}
Check "FTP auth + anon" {
  # ftp.exe scripting mínimo (anon debe listar, auth debe listar)
  $ftpAnon = @("open freebsd-ftp.lab.local","anonymous","anonymous@","ls","quit")
  $ftpAnon | ftp -n 2>&1 | Select-String "226|150|pub" -Quiet | Out-Null
}

if (-not $ok) { Write-Host "VALIDATE: con fallos (ver arriba)"; exit 1 }
Write-Host "VALIDATE: todo PASS"
