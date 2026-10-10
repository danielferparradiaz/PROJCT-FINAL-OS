# check-prereqs.ps1 — Windows host. Verifica requisitos x86_64, RAM, disco, Vagrant, provider.
$ErrorActionPreference = "Continue"
$fail = $false
Write-Host "== prereqs Windows =="
$arch = (Get-CimInstance Win32_ComputerSystem).SystemType
Write-Host "Arch: $arch"
if ($arch -notlike "*x64*") { Write-Host "FAIL: host no x64"; $fail = $true } else { Write-Host "PASS arch x64" }
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 1)
Write-Host "RAM: $ram GB (mínimo 16 recomendado)"
if ($ram -lt 12) { Write-Host "WARN RAM baja para 4 VMs" }
Get-PSDrive C | Format-Table Used, Free
foreach ($c in @("vagrant","VBoxManage")) {
  if (Get-Command $c -ErrorAction SilentlyContinue) { Write-Host "PASS $c"; & $c --version } else { Write-Host "FAIL $c no instalado"; $fail = $true }
}
Write-Host "--- boxes ---"; vagrant box list
if ($fail) { exit 1 }
