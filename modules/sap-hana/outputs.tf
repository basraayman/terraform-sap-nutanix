# ============================================================================
# SAP HANA Module Outputs
# ============================================================================

output "vm_uuid" {
  description = "UUID of the SAP HANA VM"
  value       = nutanix_virtual_machine.sap_hana.id
}

output "vm_name" {
  description = "Name of the SAP HANA VM"
  value       = nutanix_virtual_machine.sap_hana.name
}

output "ip_address" {
  description = "Primary IP address of the SAP HANA VM"
  value       = try(nutanix_virtual_machine.sap_hana.nic_list_status[0].ip_endpoint_list[0].ip, "")
}

output "all_ip_addresses" {
  description = "All IP addresses assigned to the VM"
  value = [
    for nic in nutanix_virtual_machine.sap_hana.nic_list_status :
    try(nic.ip_endpoint_list[0].ip, "")
  ]
}

output "hana_configuration" {
  description = "SAP HANA configuration details"
  value = {
    sid             = var.hana_sid
    instance_number = var.hana_instance_number
    deployment_type = var.hana_deployment_type
    system_size     = var.sap_system_size
  }
}

output "vm_resources" {
  description = "VM resource allocation"
  value = {
    memory_gb   = local.actual_memory
    vcpus       = local.actual_vcpus
    sockets     = local.num_sockets
    cores       = local.num_vcpus_per_socket
  }
}

output "storage_configuration" {
  description = "Storage layout configuration"
  value = {
    os_disk_gb     = var.os_disk_size_gb
    data_disks     = local.actual_data_disks
    data_disk_gb   = local.data_disk_size_gb
    log_disks      = local.actual_log_disks
    log_disk_gb    = local.log_disk_size_gb
    shared_disk_gb = local.shared_disk_size_gb
    backup_disk_gb = var.enable_backup_disk ? local.backup_disk_size_gb : 0
    total_storage_gb = var.os_disk_size_gb + 
                       (local.actual_data_disks * local.data_disk_size_gb) +
                       (local.actual_log_disks * local.log_disk_size_gb) +
                       local.shared_disk_size_gb +
                       (var.enable_backup_disk ? local.backup_disk_size_gb : 0)
  }
}

output "ansible_host_vars" {
  description = "Ansible host variables for configuration management"
  value = {
    ansible_host            = try(nutanix_virtual_machine.sap_hana.nic_list_status[0].ip_endpoint_list[0].ip, "")
    sap_hana_sid            = var.hana_sid
    sap_hana_instance       = var.hana_instance_number
    sap_hana_deployment     = var.hana_deployment_type
    hana_data_disk_count    = local.actual_data_disks
    hana_log_disk_count     = local.actual_log_disks
  }
}

output "fqdn" {
  description = "Fully qualified domain name (if available)"
  value       = var.vm_name
}

output "cluster_uuid" {
  description = "UUID of the Nutanix cluster hosting the VM"
  value       = nutanix_virtual_machine.sap_hana.cluster_uuid
}

output "power_state" {
  description = "Current power state of the VM"
  value       = nutanix_virtual_machine.sap_hana.power_state
}

