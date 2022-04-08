variable "wifi_name" {
  type = string
}
variable "wifi_password" {
  type = string
  sensitive = true
}
variable "local_ssh_public_key" {
  type = string
  default = "~/.ssh/id_rsa.pub"
}
locals {
  ssh_key = "${pathexpand(var.local_ssh_public_key)}"
}

variable "locales" {
    type = list(string)
    description = "List of locales to generate, as seen in `/etc/locale.gen`."
    default = ["en_US.UTF-8 UTF-8", "en_CA.UTF-8 UTF-8"]
}

variable "wpa_supplicant_enabled" {
    type = bool
    description = <<-EOT
        Create a [`wpa_supplicant.conf` file](https://www.raspberrypi.org/documentation/configuration/wireless/wireless-cli.md) on the image.
        
        If `wpa_supplicant_path` exists, it will be copied to the OS image, otherwise a basic `wpa_supplicant.conf` file will be created using `wpa_supplicant_ssid`, `wpa_supplicant_pass` and `wpa_supplicant_country`.
    EOT
    default = true
}

variable "wpa_supplicant_path" {
    type = string
    description = "The local path to existing `wpa_supplicant.conf` to copy to the image."
    default = "/tmp/dummy" # fileexists() doesn't like empty strings
}

variable "wpa_supplicant_ssid" {
    type = string
    description = "The WiFi SSID."
    default = ""
}

variable "wpa_supplicant_pass" {
    type = string
    description = "The WiFi password."
    default = ""
}

variable "wpa_supplicant_country" {
    type = string
    description = <<-EOT
        The [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code in which the device is operating.
        
        Required by the wpa_supplicant.
    EOT
    default = "CA"
}