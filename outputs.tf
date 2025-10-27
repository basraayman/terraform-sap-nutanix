# ============================================================================
# Terraform SAP on Nutanix - Root Module Outputs
# ============================================================================

output "cluster_info" {
  description = "Information about the target Nutanix cluster"
  value = {
    name = data.nutanix_cluster.cluster.name
    uuid = data.nutanix_cluster.cluster.id
  }
}

output "subnet_info" {
  description = "Information about the target subnet"
  value = {
    name = var.subnet_name
    uuid = data.nutanix_subnet.subnet.id
  }
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = local.merged_tags
}

# ============================================================================
# Module Outputs - Uncomment based on active modules
# ============================================================================

# SAP HANA Module Outputs
# output "sap_hana_vm" {
#   description = "SAP HANA VM details"
#   value = {
#     name       = module.sap_hana_db.vm_name
#     ip_address = module.sap_hana_db.ip_address
#     uuid       = module.sap_hana_db.vm_uuid
#   }
# }

# SAP NetWeaver Module Outputs
# output "sap_netweaver_vms" {
#   description = "SAP NetWeaver VM details"
#   value = {
#     pas = {
#       name       = module.sap_netweaver_pas.vm_name
#       ip_address = module.sap_netweaver_pas.ip_address
#     }
#   }
# }

# SAP S/4HANA Module Outputs
# output "sap_s4hana_landscape" {
#   description = "Complete S/4HANA landscape information"
#   value       = module.sap_s4hana.landscape_info
#   sensitive   = false
# }

# Ansible Inventory
# output "ansible_inventory" {
#   description = "Generated Ansible inventory content"
#   value       = var.generate_ansible_inventory ? local.ansible_inventory : null
# }

