variable "datacenter_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "datastore_name" {
  type = string
}

variable "network_name" {
  type = string
}

variable "vm_folder" {
  type    = string
  default = null
}

variable "vm_name" {
  type = string
}

variable "content_library_name" {
  type = string
}

variable "template_name" {
  type = string
}

variable "cpu_cores" {
  type    = number
  default = 2
}

variable "memory_gb" {
  type    = number
  default = 4
}

variable "os_disk_size_gb" {
  type    = number
  default = 40
}

variable "extra_disk_size_gb" {
  type    = number
  default = 0
}

variable "disk_type" {
  type    = string
  default = "thin"
}

variable "vm_tags" {
  type = list(object({
    name     = string
    category = string
    enabled  = bool
  }))
  default = []
}

variable "apply_customization" {
  type    = bool
  default = false
}

variable "domain_name" {
  type    = string
  default = "us.chs.net"
}

variable "static_ip" {
  type    = string
  default = ""
}

variable "netmask" {
  type    = number
  default = 24
}

variable "gateway" {
  type    = string
  default = ""
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

variable "search_domains" {
  type    = list(string)
  default = []
}

variable "admin_password" { 
  type = string 
  sensitive = true 
}
