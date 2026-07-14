terraform {
  required_version = ">= 1.5.0"
  
  backend "kubernetes" {
    secret_suffix = "dev-state"
    namespace     = "terraform-automation"
  }
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.4"
    }
    bluecat = {
      source  = "bluecatlabs/bluecat"
      version = "~> 2.3"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

# --- Root CyberArk Input Definitions ---
variable "cyberark_url" {
  type    = string
  default = "https://epass.chs.net"
}

variable "cyberark_username" {
  type    = string
  default = "Ansible_api"
}

variable "cyberark_password" {
  type      = string
  sensitive = true
}

variable "cyberark_validate_certs" {
  type    = bool
  default = false
}

variable "vcenter_host" {
  type    = string
  default = "vcenter.lhn.local"
}

variable "vcenter_validate_ssl" {
  type    = bool
  default = false
}

data "external" "vcenter_secret" {
  program = ["python3", "${path.module}/../../scripts/fetch_secret.py"]
  query = {
    cyberark_url          = var.cyberark_url
    cyberark_username     = var.cyberark_username
    cyberark_password     = var.cyberark_password
    cyberark_safe         = "D-OA-AnsibleSolution"
    cyberark_account_name = "us_d-oa-vmware-svc"
    validate_certs        = tostring(var.cyberark_validate_certs)
  }
}

data "external" "bluecat_secret" {
  program = ["python3", "${path.module}/../../scripts/fetch_secret.py"]

  # FORCE SEQUENTIAL EXECUTION: Prevents session token invalidation
  depends_on = [data.external.vcenter_secret]

  query = {
    cyberark_url          = var.cyberark_url
    cyberark_username     = var.cyberark_username
    cyberark_password     = var.cyberark_password
    cyberark_safe         = "D-OA-AnsibleSolution"
    cyberark_account_name = "us_d-oa-bc-svc"
    validate_certs        = tostring(var.cyberark_validate_certs)
  }
}

data "external" "guest_admin_secret" {
  program = ["python3", "${path.module}/../../scripts/fetch_secret.py"]

  # FORCE SEQUENTIAL EXECUTION: Wait for BlueCat to complete cleanly
  depends_on = [data.external.bluecat_secret]

  query = {
    cyberark_url          = var.cyberark_url
    cyberark_username     = var.cyberark_username
    cyberark_password     = var.cyberark_password
    cyberark_safe         = "D-OA-AnsibleSolution"
    cyberark_account_name = "Administrator"
    validate_certs        = tostring(var.cyberark_validate_certs)
  }
}

# --- Provider Initializations ---
provider "vsphere" {
  user                 = "us_d-oa-vmware-svc@us.chs.net"
  password             = data.external.vcenter_secret.result.secret
  vsphere_server       = var.vcenter_host
  allow_unverified_ssl = true
}

#provider "bluecat" {
#  server           = "bam.chs.net"
#  port             = 443
#  transport        = "https"
#  username         = "us_d-oa-bc-svc"
#  password         = data.external.bluecat_secret.result.secret
#  api_version      = "1"
#  encrypt_password = false
#}

