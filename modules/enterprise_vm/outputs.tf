output "vm_uuid" {
  description = "The VMware hardware UUID of the deployed virtual machine."
  value       = vsphere_virtual_machine.vm.uuid
}

output "vm_ip_address" {
  description = "The canonical IPv4 address reported back by VMware Tools."
  value       = vsphere_virtual_machine.vm.default_ip_address
}
