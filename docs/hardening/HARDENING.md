# Hardening Oracle / FreeBSD / Windows (resumen)

## Oracle (`provisioning/oracle-linux/00-base.sh`, validar `security/oracle-hardening-check.sh`)
Usuarios (opsadmin, root no SSH), sshd sin password/empty/X11 + banner, firewalld (ssh/http/https + samba solo lab), SELinux enforcing, servicios mínimos desactivados, auditd reglas identity/auth/web/samba, dnf-automatic security, sudo log, umask 027. Recuperación: snapshots + `/etc/ssh/sshd_config.bak.*`.

## FreeBSD (`provisioning/freebsd/00-base.sh`, validar `security/freebsd-hardening-check.sh`)
opsadmin wheel, root no SSH/claves, pf (22/21+pasivo solo lab), sendmail/rpcbind off, auditd, freebsd-update cron, sudo log. FTP anónimo: `/var/ftp/pub` 555 solo-lectura, sin upload/mkdir, `anon_world_readable_only`; autenticado chroot `~/ftp` 555 + `upload/` propio. Recuperación: snapshots + `/etc/ssh/sshd_config.bak`.

## Windows (`provisioning/windows-server/00-base.ps1` + GPO tras DC, validar `security/windows-audit.ps1`)
Firewall perfiles on + WinRM/RDP solo lab, WinRM Negotiate sin Basic ni AllowUnencrypted, auditpol logon/account/policy, `net accounts` baseline (min 10, lockout 5), updates manuales en demo (no auto-reboot), post-DC endurecer con GPO (password, lockout, UAC, SMB signing). Recuperación: snapshot predemo + DSRM password (env, fuera de repo).
El hardening no bloquea servicios: puertos académicos abiertos solo a `192.168.56.0/24`, guest/anon escritura prohibidos.
