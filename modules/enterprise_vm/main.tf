terraform {
  required_providers {
    vsphere = {
      source  = "vmware/vsphere"
      version = "~> 2.4"
    }
  }
}

# --- Data Sources to resolve names to Managed Object IDs ---

data "vsphere_datacenter" "dc" {
  name = var.datacenter_name
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_content_library" "library" {
  name = var.content_library_name
}

data "vsphere_content_library_item" "template" {
  name       = var.template_name
  library_id = data.vsphere_content_library.library.id
  type       = "ovf"
}

# --- Tag Discovery ->Fail inthe plan if it c an't find it ---

data "vsphere_tag_category" "categories" {
  for_each = { for tag in var.vm_tags : "${tag.category}/${tag.name}" => tag if tag.enabled }
  name     = each.value.category
}

data "vsphere_tag" "tags" {
  for_each    = { for tag in var.vm_tags : "${tag.category}/${tag.name}" => tag if tag.enabled }
  name        = each.value.name
  category_id = data.vsphere_tag_category.categories[each.key].id
}

# --- Virtual Machine Definition ---

resource "vsphere_virtual_machine" "vm" {
  name             = var.vm_name
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id
  folder           = var.vm_folder

  num_cpus = var.cpu_cores
  memory   = var.memory_gb * 1024 # Converts GB to MB
  
  firmware                = "bios"
  #efi_secure_boot_enabled = true

  # Dynamically add a second controller if an extra disk is specified
  scsi_controller_count = 1
  scsi_type             = "pvscsi" # "pvscsi" # the Defaulting to Paravirtual broke tf

  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  # OS Root Disk (Inherited or explicitly provisioned)
  disk {
    label            = "disk0"
    size             = var.os_disk_size_gb
    thin_provisioned = var.disk_type == "thin" ? true : false
    eagerly_scrub    = var.disk_type == "eagerZeroedThick" ? true : false
    unit_number      = 0
  }

  # Phase 2: Conditional Hardware Convergence (Extra Data Disk)
  dynamic "disk" {
    for_each = var.extra_disk_size_gb > 0 ? [1] : []
    content {
      label            = "disk1"
      size             = var.extra_disk_size_gb
      thin_provisioned = var.disk_type == "thin" ? true : false
      # Formula for SCSI(1:0) mapping: controller_index (1) * 15 + device_slot (0) = 15
      eagerly_scrub    = var.disk_type == "eagerZeroedThick" ? true : false
      unit_number      = 1 
    }
  }

  # Phase 2 Alignment: Assign dynamic tag IDs discovered above
  tags = [for t in data.vsphere_tag.tags : t.id]

  # Phase 1, 3, & 4: Deployment & Automatic State Waiters
  clone {
    template_uuid = data.vsphere_content_library_item.template.id
    timeout       = 60 # overriding that default 20min thingy

    # Inline Guest Customization (Replaces BlueCat setup blocks)
    dynamic "customize" {
      for_each = var.apply_customization && var.static_ip != "" ? [1] : []
      content {
        windows_options {
                computer_name  = var.vm_name
                admin_password = var.admin_password
              }
        network_interface {
          ipv4_address = var.static_ip
          ipv4_netmask = var.netmask
        }

        ipv4_gateway    = var.gateway
        dns_server_list = var.dns_servers
        dns_suffix_list = var.search_domains
      }
    }
  }

  # Native built-in timeout waiting for guest network to report an IP via VMware Tools
  wait_for_guest_net_routable = false
  wait_for_guest_net_timeout = 30

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid, # Ignore template updates after initial deployment
      disk,                   # Prevents conflicts if guest OS alters partition layouts
    ]
  }

}
