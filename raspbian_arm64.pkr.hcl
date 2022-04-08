locals {
  wpa_supplicant = <<-EOF
  ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
  update_config=1
  country=${upper(var.wpa_supplicant_country)}

  network={
      ssid="${var.wifi_name}"
      psk="${var.wifi_password}"
  }
  EOF

  # /etc/locale.gen
  localgen = join("\n", var.locales)
}

source "arm" "raspberry_pi_os" {
  file_checksum  = "d694d2838018cf0d152fe81031dba83182cee79f785c033844b520d222ac12f5"
  file_urls      = ["https://downloads.raspberrypi.org/raspios_lite_arm64/images/raspios_lite_arm64-2022-01-28/2022-01-28-raspios-bullseye-arm64-lite.zip"]
  file_checksum_type    = "sha256"
  image_build_method    = "resize"
  file_target_extension = "zip"
  

  image_partitions {
    name = "boot"
    type = "c"
    start_sector = "8192"
    filesystem = "vfat"
    size = "256M"
    mountpoint = "/boot"
  }
  image_partitions {
    name = "root"
    type = "83"
    start_sector = "532480"
    filesystem = "ext4"
    size = "0"
    mountpoint = "/"
  }

  image_path       = "raspios-arm64-${uuidv4()}.img"
  image_setup_extra = []
  image_size       = "6G"
  image_type       = "dos"
  image_chroot_env = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  qemu_binary_source_path = "/usr/bin/qemu-aarch64-static"
  qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"
  
}

build {
  sources = ["source.arm.raspberry_pi_os"]
  #type = "arm"

  
  # enable ssh
  provisioner "shell" {
    inline = [
      "touch /boot/ssh",
      "mkdir /home/pi/.ssh"
    ]
  }

  # enable wifi
  # Generate /etc/wpa_supplicant/wpa_supplicant.conf (if enabled)
    # NB: send to /dev/null to prevent secrets from showing up in log
    # NB: the <tabs> for the indented HEREDOC
  provisioner "shell" {
    inline = [
    <<-EOF
        %{ if var.wpa_supplicant_enabled }
    tee /boot/wpa_supplicant.conf <<- CONFIG > /dev/null
    %{~ if fileexists(var.wpa_supplicant_path) ~}
    ${ file(var.wpa_supplicant_path) }
    %{ else }
    ${ local.wpa_supplicant }
    %{ endif }
    CONFIG
        %{ else }
        echo "wpa_supplicant disabled."
        %{ endif }
    EOF
    ]
  }

  # Add locales that will get generated on first boot
  # (by cloud-init's 'locale' module) 
  provisioner "shell" {
      inline = [
      <<-EOF
    tee -a /etc/locale.gen <<- CONFIG
      ${local.localgen}
      CONFIG
      EOF
      ]
  }
  
  # copy public key
  provisioner "file" {
    source = "${local.ssh_key}"
    destination = "/home/pi/.ssh/authorized_keys"
  }

  # disable password auth
  provisioner "shell" {
    inline = [
        "chown pi:pi /home/pi/.ssh/authorized_keys",
        "sed '/PasswordAuthentication/d' -i /etc/ssh/sshd_config",
        "echo >> /etc/ssh/sshd_config",
        "echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config",
      ]
  }

  # update and install packages
  provisioner "shell" {
      inline = [
          "apt-get update",
          "apt-get install -y python3 golang build-essential python-dev python3-pip vim",
          "apt-get install -y libgpiod2"
      ]
  }
}