# --- Root Configuration Variable Controls ---
variable "bluecat_subnet" {
  type    = string
  default = "10.32.16.0/24"
}

variable "vm_name" {
  type    = string
  default = "MooreTF"
}

# Step 2: Dynamic BlueCat IPAM Static Reservation Block
#resource "bluecat_ip_allocation" "reserved_ip" {
#  configuration = "CHS-Internal"
#  view          = "Internal"
#  zone          = "us.chs.net"
#  name          = "${var.vm_name}.us.chs.net"
#  network       = var.bluecat_subnet
#  action        = "MAKE_STATIC"
#}

# Step 3 & 4: Deploy VM and Inject BlueCat Provision Values
module "deploy_windows_vm" {
  source = "../../modules/enterprise_vm"

  datacenter_name      = "BOC - IN8225"
  cluster_name         = "Win"
  datastore_name       = "VM-Win-Dump"
  network_name         = "10.32.28.x -- v1500"
  vm_name              = var.vm_name
  content_library_name = "WinContentLibrary_subscribed"

  template_name        = "22STDQ4"


  # Sizing Specs
  cpu_cores           = 2
  memory_gb           = 4
  os_disk_size_gb     = 100
  extra_disk_size_gb  = 50
  disk_type           = "thin"

  # Network Customization Pass-through
  apply_customization = true
  static_ip           = "10.11.165.129" #bluecat_ip_allocation.reserved_ip.ip_address
  netmask             = 24
  gateway             = "10.32.16.1"
  dns_servers         = ["10.100.1.10", "10.100.1.11"]
  domain_name         = "us.chs.net"
  search_domains      = ["us.chs.net"]
  
  # Admin Password assignment resolved from CyberArk map
  admin_password      = data.external.guest_admin_secret.result.secret
}
