variable "image_username" {
  default = "packer"
}

variable "image_password" {
  default = "packer"
}

locals {
  build_stamp = formatdate("YYYYMMDDhhmmss", timestamp())
}

source "vsphere-iso" "ubuntu" {
  vcenter_server = "example.com"
  username = "administrator@example.com"
  password = "verysecurepasswordgoeshere"
  insecure_connection = true

  vm_name = "ubuntu-18-04-${local.build_stamp}"
  guest_os_type = "ubuntu64guest"
  ssh_username = var.image_username
  ssh_password = var.image_password
  convert_to_template = true

  CPUs = 2
  RAM = 1024
  RAM_reserve_all = true

  #disk_controller_type = "pvscsi"
  disk_size = 8124
  disk_thin_provisioned = true

  network_card = "vmxnet3"

  # Location of .iso file to boot from
  iso_paths = [
    "[storageserver] isos/ubuntu-18.04.4-server-amd64.iso"
  ]
  
  # Load the config for initial Ubuntu setup prompts
  floppy_files = [
    "preseed.cfg"
  ]
  
  # Press the required keys to boot the vm using the iso file
  boot_command = [
    "<enter><wait><f6><wait><esc><wait>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs><bs><bs><bs><bs><bs><bs><bs>",
    "<bs><bs><bs>",
    "/install/vmlinuz",
    " initrd=/install/initrd.gz",
    " priority=critical",
    " locale=en_US",
    " file=/media/preseed.cfg",
    "<enter>",
  ]

  host = "esxi-1.example.com"
  datastore = "esxi-1-local"
  cluster = "example" 
}

build {
  sources = [
    "source.vsphere-iso.ubuntu"
  ]
  
  # Prep for Gitlab deploy key
  provisioner "shell" {
    execute_command = "echo '${ var.image_password }' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "mkdir /root/.ssh",
      "chown root:root /root/.ssh",
      "chmod 700 /root/.ssh"
    ]
  }

  # Copy Gitlab deploy key
  # Will be used to clone ansible repo to auto-apply config
  provisioner "file" {
    source = "secrets/gitlab-deploy"
    destination = "/home/packer/id_rsa"
  }
  
  # Install Gitlab deploy key and use it in ssh config
  provisioner "shell" {
    execute_command = "echo '${ var.image_password }' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "mv /home/packer/id_rsa /root/.ssh/id_rsa",
      "chown root:root /root/.ssh/id_rsa",
      "chmod 600 /root/.ssh/id_rsa",
      "echo Host gitbox.dorwinia.com >> /root/.ssh/config",
      "echo StrictHostKeyChecking no >> /root/.ssh/config"
    ]
  }

  # Install prereq datasource for cloud-init to recognize vsphere guestinfo
  # https://grantorchard.com/terraform-vsphere-cloud-init/ under "Prerequisites"
  provisioner "shell" {
    execute_command = "echo '${ var.image_password }' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt update",
      "apt install -y curl python3-pip",
      "curl -sSL https://raw.githubusercontent.com/vmware/cloud-init-vmware-guestinfo/master/install.sh | sh -"
    ]
  }

  # Install minimal packages and Ansible prerequisites
  provisioner "shell" {
    execute_command = "echo '${ var.image_password }' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt update",
      "apt install -y vim git software-properties-common",
      "apt-add-repository --yes --update ppa:ansible/ansible",
      "apt install -y ansible"
    ]
  }
  
  # Install common packages
  provisioner "shell" {
    execute_command = "echo '${ var.image_password }' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt update",
      "apt install -y tree vim sl nmap tmux htop curl wget unzip traceroute rsync"
    ]
  }

  # Update system packages
  provisioner "shell" {
    execute_command = "echo '${ var.image_password }' | sudo -S sh -c '{{ .Vars }} {{ .Path }}'"
    inline = [
      "apt update",
      "apt upgrade -y",
      "apt autoremove -y"
    ]
  }
}
