# -*- mode: ruby -*-
# vi: set ft=ruby :
# Laboratorio reproducible: Oracle Linux (web/wiki/samba) + FreeBSD (ftp) + WinServer (AD/DNS/DHCP) + Win10 (cliente)
# Host objetivo: x86_64. Ver docs/architecture/COMPATIBILITY.md para Apple Silicon.
# Uso:
#   vagrant validate
#   vagrant up windows-dc --provider=virtualbox
#   vagrant up oracle-web freebsd-ftp --provider=virtualbox
#   vagrant up windows-client --provider=virtualbox
#   vagrant up  (laboratorio completo, con --no-parallel recomendado en Windows)
# No guardar secretos en este archivo. Ver config/lab.yml + README.md

require 'yaml'

LAB = YAML.load_file(File.join(File.dirname(__FILE__), 'config', 'lab.yml'))

Vagrant.configure("2") do |config|
  # No usar update de guest additions automático sin plugin; documentado en README.
  # Desactivar carpeta compartida por defecto (se habilita solo donde se necesita).
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # ---------- Oracle Linux: web/wiki/samba ----------
  config.vm.define "oracle-web", primary: false, autostart: true do |m|
    c = LAB['machines']['oracle-web']
    m.vm.box = c['box']
    m.vm.hostname = "oracle-web"
    m.vm.network "private_network", ip: c['ip_lab']
    (c['forwarded_ports'] || []).each do |fp|
      m.vm.network "forwarded_port", guest: fp['guest'], host: fp['host'], auto_correct: true
    end
    m.vm.provider "virtualbox" do |v|
      v.name = "oracle-web"
      v.cpus = c['cpus']
      v.memory = c['memory']
      v.linked_clone = true
    end
    m.vm.provider "vmware_desktop" do |v|
      v.vmx["numvcpus"] = c['cpus'].to_s
      v.vmx["memsize"] = c['memory'].to_s
    end
    # Provisionamiento idempotente por etapas
    m.vm.provision "base", type: "shell", path: "provisioning/oracle-linux/00-base.sh"
    m.vm.provision "web-wiki", type: "shell", path: "provisioning/oracle-linux/10-web-wiki.sh"
    m.vm.provision "samba", type: "shell", path: "provisioning/oracle-linux/20-samba.sh"
  end

  # ---------- FreeBSD: FTP ----------
  config.vm.define "freebsd-ftp", primary: false, autostart: true do |m|
    c = LAB['machines']['freebsd-ftp']
    m.vm.box = c['box']
    m.vm.hostname = "freebsd-ftp"
    # FreeBSD + VirtualBox: usar virtio para rendimiento; synced_folder por rsync o desactivado.
    m.vm.network "private_network", ip: c['ip_lab']
    (c['forwarded_ports'] || []).each do |fp|
      m.vm.network "forwarded_port", guest: fp['guest'], host: fp['host'], auto_correct: true
    end
    m.vm.provider "virtualbox" do |v|
      v.name = "freebsd-ftp"
      v.cpus = c['cpus']
      v.memory = c['memory']
      v.linked_clone = true
      v.default_nic_type = "virtio"
    end
    m.vm.provider "vmware_desktop" do |v|
      v.vmx["numvcpus"] = c['cpus'].to_s
      v.vmx["memsize"] = c['memory'].to_s
    end
    m.vm.provision "base", type: "shell", path: "provisioning/freebsd/00-base.sh"
    m.vm.provision "ftp", type: "shell", path: "provisioning/freebsd/10-ftp.sh"
  end

  # ---------- Windows Server: AD/DNS/DHCP ----------
  config.vm.define "windows-dc", primary: true, autostart: true do |m|
    c = LAB['machines']['windows-dc']
    m.vm.box = c['box']
    m.vm.hostname = "windows-dc"
    m.vm.communicator = "winrm"
    m.winrm.transport = :negotiate
    m.winrm.basic_auth_only = false
    m.winrm.timeout = c.fetch('winrm_timeout', 600)
    m.winrm.max_tries = 30
    # IP estática en red lab. auto_config true (Vagrant la configura).
    m.vm.network "private_network", ip: c['ip_lab']
    m.vm.provider "virtualbox" do |v|
      v.name = "windows-dc"
      v.cpus = c['cpus']
      v.memory = c['memory']
      v.linked_clone = true
    end
    m.vm.provider "vmware_desktop" do |v|
      v.vmx["numvcpus"] = c['cpus'].to_s
      v.vmx["memsize"] = c['memory'].to_s
    end
    # Etapa 1: base (requiere reboot) -> reload -> Etapa 2: AD/DNS -> reboot -> Etapa 3: DHCP
    m.vm.provision "base", type: "shell", privileged: true,
      path: "provisioning/windows-server/00-base.ps1",
      powershell_elevated_interactive: false
    m.vm.provision "reload-after-base", type: "reload"
    m.vm.provision "ad-dns", type: "shell", privileged: true,
      path: "provisioning/windows-server/10-ad-dns.ps1"
    m.vm.provision "reload-after-ad", type: "reload"
    m.vm.provision "dhcp", type: "shell", privileged: true,
      path: "provisioning/windows-server/20-dhcp.ps1"
  end

  # ---------- Windows 10: cliente ----------
  config.vm.define "windows-client", primary: false, autostart: true do |m|
    c = LAB['machines']['windows-client']
    m.vm.box = c['box']
    m.vm.hostname = "windows-client"
    m.vm.communicator = "winrm"
    m.winrm.transport = :negotiate
    m.winrm.timeout = 600
    m.winrm.max_tries = 30
    # CRÍTICO: no dejar que Vagrant configure IP. El cliente debe obtenerla por DHCP del DC.
    # Esto adjunta la NIC a la red host-only pero deja la configuración a Windows DHCP.
    m.vm.network "private_network", ip: c['ip_expected'], auto_config: false
    m.vm.provider "virtualbox" do |v|
      v.name = "windows-client"
      v.cpus = c['cpus']
      v.memory = c['memory']
      v.linked_clone = true
    end
    m.vm.provider "vmware_desktop" do |v|
      v.vmx["numvcpus"] = c['cpus'].to_s
      v.vmx["memsize"] = c['memory'].to_s
    end
    m.vm.provision "join", type: "shell", privileged: true,
      path: "provisioning/windows-client/00-join-domain.ps1"
    m.vm.provision "reload-after-join", type: "reload"
    m.vm.provision "validate", type: "shell", privileged: true,
      path: "provisioning/windows-client/10-validate.ps1"
  end

  # Orden sugerido (documentado, no forzado por Vagrant):
  #   vagrant up windows-dc --no-parallel
  #   vagrant up oracle-web freebsd-ftp --no-parallel
  #   vagrant up windows-client
end
