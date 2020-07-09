variable "do_token" {}

variable "region" {
  default="fra1"
}

provider "digitalocean" {
  token = var.do_token
}

resource "digitalocean_ssh_key" "default" {
  name       = "Sample key"
  public_key = file("${path.module}/files/key_rsa.pub")
}

resource "digitalocean_droplet" "web" {
  image  = "ubuntu-18-04-x64"
  name   = "web-1"
  region = var.region
  size   = "s-1vcpu-1gb"
  ssh_keys = [digitalocean_ssh_key.default.fingerprint]
}

resource "digitalocean_firewall" "web" {
  name = "5000-and-ssh"

  droplet_ids = [digitalocean_droplet.web.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "5000"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }


  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}


locals {
  ansible_command_engine = "ansible-playbook -i ${digitalocean_droplet.web.ipv4_address}, --user root --private-key files/key_rsa playbook.yml"
}

resource "null_resource" "ansible_provision" {

  provisioner "local-exec" {
    command = local.ansible_command_engine
    environment = {
      ANSIBLE_HOST_KEY_CHECKING="False"
    }
  }
}


output "dns" {
  value = digitalocean_droplet.web.ipv4_address
}
