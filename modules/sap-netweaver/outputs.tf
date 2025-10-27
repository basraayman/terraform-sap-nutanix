# ============================================================================
# SAP NetWeaver Module Outputs
# ============================================================================

output "vm_uuid" {
  description = "UUID of the SAP NetWeaver VM"
  value       = nutanix_virtual_machine.sap_netweaver.id
}

output "vm_name" {
  description = "Name of the SAP NetWeaver VM"
  value       = nutanix_virtual_machine.sap_netweaver.name
}

output "ip_address" {
  description = "Primary IP address of the SAP NetWeaver VM"
  value       = try(nutanix_virtual_machine.sap_netweaver.nic_list_status[0].ip_endpoint_list[0].ip, "")
}

output "all_ip_addresses" {
  description = "All IP addresses assigned to the VM"
  value = [
    for nic in nutanix_virtual_machine.sap_netweaver.nic_list_status :
    try(nic.ip_endpoint_list[0].ip, "")
  ]
}

output "netweaver_configuration" {
  description = "SAP NetWeaver configuration details"
  value = {
    sid             = var.sap_sid
    instance_number = var.instance_number
    instance_type   = var.instance_type
    stack_type      = var.stack_type
  }
}

output "vm_resources" {
  description = "VM resource allocation"
  value = {
    memory_gb   = var.memory_gb
    vcpus       = var.num_vcpus
    sockets     = local.num_sockets
    cores       = local.num_vcpus_per_socket
  }
}

output "storage_configuration" {
  description = "Storage layout configuration"
  value = {
    os_disk_gb     = var.os_disk_size_gb
    usrsap_disk_gb = var.usrsap_disk_size_gb
    sapmnt_disk_gb = var.sapmnt_disk_size_gb
  }
}

output "ansible_host_vars" {
  description = "Ansible host variables for configuration management"
  value = {
    ansible_host            = try(nutanix_virtual_machine.sap_netweaver.nic_list_status[0].ip_endpoint_list[0].ip, "")
    sap_sid                 = var.sap_sid
    sap_instance_number     = var.instance_number
    sap_instance_type       = var.instance_type
    sap_stack_type          = var.stack_type
  }
}

output "cluster_uuid" {
  description = "UUID of the Nutanix cluster hosting the VM"
  value       = nutanix_virtual_machine.sap_netweaver.cluster_uuid
}

output "power_state" {
  description = "Current power state of the VM"
  value       = nutanix_virtual_machine.sap_netweaver.power_state
}

