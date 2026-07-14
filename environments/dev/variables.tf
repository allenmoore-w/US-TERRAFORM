variable "datacenter_name" {
  type    = string
  default = "BOC - IN8225"
}

variable "cluster_name" {
  type    = string
  default = "Win"
}

variable "datastore_name" {
  type    = string
  default = "VM-Win-Dump"
}

variable "network_name" {
  type    = string
  default = "10.32.28.x -- v1500"
}

variable "content_library_name" {
  type    = string
  default = "Golden-Images"
}

variable "template_name" {
  type    = string
  default = "22STDQ4"
}

variable "static_ip" {
  type    = string
  default = ""
}

variable "gateway" {
  type    = string
  default = ""
}

variable "dns_servers" {
  type    = list(string)
  default = []
}
