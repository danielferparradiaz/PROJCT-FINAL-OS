# Auditoría Windows (solo lectura) — ejecutar vía WinRM: vagrant powershell / Invoke-Command.
# Cubre AD/DNS/DHCP + baseline seguridad. No modifica.
$ErrorActionPreference = "Continue"
Write-Host "== Windows audit =="
Write-Host "-- AD --"; try { Get-ADDomain | Format-Table DNSRoot,NetBIOSName } catch { Write-Host "FAIL AD: $_" }
Write-Host "-- DNS --"; try { Get-DnsServerZone | Format-Table ZoneName,IsAutoCreated } catch { Write-Host "FAIL DNS: $_" }
Write-Host "-- DHCP --"; try { Get-DhcpServerv4Scope | Format-Table Name,StartRange,EndRange,State } catch { Write-Host "FAIL DHCP: $_" }
Write-Host "-- Firewall --"; Get-NetFirewallProfile | Format-Table Name,Enabled
Write-Host "-- AuditPol --"; auditpol /get /category:*
Write-Host "-- Usuarios dominio --"; try { Get-ADUser -Filter * -SearchBase "OU=Lab,DC=lab,DC=local" | Format-Table SamAccountName,Enabled } catch {}
