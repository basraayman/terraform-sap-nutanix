# ============================================================================
# SAP S/4HANA Module Outputs
# ============================================================================

output "landscape_info" {
  description = "Complete S/4HANA landscape information"
  value = {
    sap_sid        = var.sap_sid
    landscape_type = var.landscape_type
    stack_type     = var.stack_type
    total_vms      = local.total_vms
  }
}

# ============================================================================
# HANA Database Outputs
# ============================================================================

output "hana_database" {
  description = "HANA database information"
  value = {
    vm_uuid    = module.hana_database.vm_uuid
    vm_name    = module.hana_database.vm_name
    ip_address = module.hana_database.ip_address
    resources  = module.hana_database.vm_resources
    storage    = module.hana_database.storage_configuration
  }
}

# ============================================================================
# Central Services Outputs
# ============================================================================

output "ascs_instance" {
  description = "ASCS instance information"
  value = var.deploy_ascs ? {
    vm_uuid    = module.ascs_instance[0].vm_uuid
    vm_name    = module.ascs_instance[0].vm_name
    ip_address = module.ascs_instance[0].ip_address
  } : null
}

output "ers_instance" {
  description = "ERS instance information"
  value = var.deploy_ers ? {
    vm_uuid    = module.ers_instance[0].vm_uuid
    vm_name    = module.ers_instance[0].vm_name
    ip_address = module.ers_instance[0].ip_address
  } : null
}

# ============================================================================
# Application Server Outputs
# ============================================================================

output "pas_instance" {
  description = "Primary Application Server information"
  value = {
    vm_uuid    = module.pas_instance.vm_uuid
    vm_name    = module.pas_instance.vm_name
    ip_address = module.pas_instance.ip_address
    resources  = module.pas_instance.vm_resources
  }
}

output "aas_instances" {
  description = "Additional Application Servers information"
  value = [
    for vm in module.aas_instances : {
      vm_uuid    = vm.vm_uuid
      vm_name    = vm.vm_name
      ip_address = vm.ip_address
      resources  = vm.vm_resources
    }
  ]
}

output "web_dispatcher" {
  description = "Web Dispatcher information"
  value = var.deploy_web_dispatcher ? {
    vm_uuid    = module.web_dispatcher[0].vm_uuid
    vm_name    = module.web_dispatcher[0].vm_name
    ip_address = module.web_dispatcher[0].ip_address
  } : null
}

# ============================================================================
# Connection Information
# ============================================================================

output "connection_info" {
  description = "Connection information for the SAP system"
  value = {
    database_host = module.hana_database.ip_address
    ascs_host     = var.deploy_ascs ? module.ascs_instance[0].ip_address : null
    pas_host      = module.pas_instance.ip_address
    
    # SAP GUI connection
    sap_gui_connection = "${module.pas_instance.ip_address}:32${var.pas_instance_number}"
    
    # Web access (if Web Dispatcher is deployed)
    web_url = var.deploy_web_dispatcher ? "https://${module.web_dispatcher[0].ip_address}:443${var.web_dispatcher_instance_number}" : null
  }
}

# ============================================================================
# All VMs Summary
# ============================================================================

output "all_vms" {
  description = "Summary of all VMs in the landscape"
  value = concat(
    [{
      name       = module.hana_database.vm_name
      ip_address = module.hana_database.ip_address
      role       = "HANA Database"
    }],
    var.deploy_ascs ? [{
      name       = module.ascs_instance[0].vm_name
      ip_address = module.ascs_instance[0].ip_address
      role       = "ASCS"
    }] : [],
    var.deploy_ers ? [{
      name       = module.ers_instance[0].vm_name
      ip_address = module.ers_instance[0].ip_address
      role       = "ERS"
    }] : [],
    [{
      name       = module.pas_instance.vm_name
      ip_address = module.pas_instance.ip_address
      role       = "PAS"
    }],
    [for vm in module.aas_instances : {
      name       = vm.vm_name
      ip_address = vm.ip_address
      role       = "AAS"
    }],
    var.deploy_web_dispatcher ? [{
      name       = module.web_dispatcher[0].vm_name
      ip_address = module.web_dispatcher[0].ip_address
      role       = "Web Dispatcher"
    }] : []
  )
}

# ============================================================================
# Ansible Inventory Path
# ============================================================================

output "ansible_inventory_path" {
  description = "Path to generated Ansible inventory file"
  value       = var.generate_ansible_inventory ? var.ansible_inventory_path : null
}

