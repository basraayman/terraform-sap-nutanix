# ============================================================================
# Example: SAP S/4HANA Distributed System
# ============================================================================
#
# This example demonstrates deploying a complete distributed SAP S/4HANA
# system on Nutanix with:
# - SAP HANA database
# - ASCS (Central Services)
# - ERS (for HA)
# - PAS (Primary Application Server)
# - 2x AAS (Additional Application Servers)
# - Web Dispatcher
#
# ============================================================================

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "~> 1.9.0"
    }
  }
}

# ============================================================================
# Provider Configuration
# ============================================================================

provider "nutanix" {
  username     = var.nutanix_username
  password     = var.nutanix_password
  endpoint     = var.nutanix_endpoint
  port         = 9440
  insecure     = true
  wait_timeout = 60
}

# ============================================================================
# Data Sources
# ============================================================================

data "nutanix_cluster" "cluster" {
  name = var.cluster_name
}

data "nutanix_subnet" "subnet" {
  subnet_name = var.subnet_name
}

# ============================================================================
# SAP S/4HANA Complete System
# ============================================================================

module "s4hana_system" {
  source = "../../modules/sap-s4hana"

  # Infrastructure
  cluster_uuid = data.nutanix_cluster.cluster.id
  subnet_uuid  = data.nutanix_subnet.subnet.id

  # SAP System Configuration
  sap_sid        = var.sap_sid
  landscape_type = "distributed"
  stack_type     = "ABAP"

  # ============================================================================
  # HANA Database (Large - 512 GB)
  # ============================================================================
  hana_instance_number = "00"
  hana_vm_config = {
    memory_gb         = 512
    num_vcpus         = 64
    image_name        = var.os_image_name
    system_size       = "L"
    enable_backup_disk = true
    ip_address        = var.ip_base != "" ? "${var.ip_base}.10" : ""
  }

  # ============================================================================
  # ASCS (Central Services)
  # ============================================================================
  deploy_ascs          = true
  ascs_instance_number = "01"
  ascs_vm_config = {
    memory_gb          = 32
    num_vcpus          = 8
    image_name         = var.os_image_name
    sapmnt_disk_size_gb = 500
    ip_address         = var.ip_base != "" ? "${var.ip_base}.11" : ""
  }

  # ============================================================================
  # ERS (Enqueue Replication Server - for HA)
  # ============================================================================
  deploy_ers          = true
  ers_instance_number = "02"
  ers_vm_config = {
    memory_gb   = 32
    num_vcpus   = 8
    image_name  = var.os_image_name
    ip_address  = var.ip_base != "" ? "${var.ip_base}.12" : ""
  }

  # ============================================================================
  # PAS (Primary Application Server)
  # ============================================================================
  pas_instance_number = "00"
  pas_vm_config = {
    memory_gb          = 128
    num_vcpus          = 32
    image_name         = var.os_image_name
    usrsap_disk_size_gb = 200
    ip_address         = var.ip_base != "" ? "${var.ip_base}.20" : ""
  }

  # ============================================================================
  # AAS (Additional Application Servers)
  # ============================================================================
  additional_app_servers = [
    {
      memory_gb          = 128
      num_vcpus          = 32
      image_name         = var.os_image_name
      usrsap_disk_size_gb = 150
      ip_address         = var.ip_base != "" ? "${var.ip_base}.21" : ""
    },
    {
      memory_gb          = 128
      num_vcpus          = 32
      image_name         = var.os_image_name
      usrsap_disk_size_gb = 150
      ip_address         = var.ip_base != "" ? "${var.ip_base}.22" : ""
    }
  ]

  # ============================================================================
  # Web Dispatcher (Load Balancer)
  # ============================================================================
  deploy_web_dispatcher        = true
  web_dispatcher_instance_number = "80"
  web_dispatcher_vm_config = {
    memory_gb   = 32
    num_vcpus   = 16
    image_name  = var.os_image_name
    ip_address  = var.ip_base != "" ? "${var.ip_base}.30" : ""
  }

  # ============================================================================
  # Cloud-Init Configuration (Applied to all VMs)
  # ============================================================================
  cloud_init_config = {
    ssh_authorized_keys = var.ssh_keys
    additional_packages = [
      "tuned-profiles-sap-hana",
      "sapconf",
      "resource-agents-sap-hana",
      "sap-suse-cluster-connector",
    ]
    timezone = var.timezone
  }

  # ============================================================================
  # Ansible Integration
  # ============================================================================
  generate_ansible_inventory = true
  ansible_inventory_path     = "./ansible/inventory/${var.sap_sid}"
  ansible_user               = "root"

  # ============================================================================
  # Tags and Organization
  # ============================================================================
  tags = merge(
    var.tags,
    {
      Environment  = var.environment
      Application  = "S4HANA"
      SAPSystem    = var.sap_sid
      Architecture = "Distributed"
    }
  )
}

# ============================================================================
# Outputs
# ============================================================================

output "landscape_summary" {
  description = "Complete S/4HANA landscape summary"
  value = {
    sap_sid     = var.sap_sid
    environment = var.environment
    landscape   = module.s4hana_system.landscape_info
    vms_count   = length(module.s4hana_system.all_vms)
  }
}

output "all_systems" {
  description = "All VMs in the landscape"
  value       = module.s4hana_system.all_vms
}

output "connection_info" {
  description = "SAP system connection information"
  value       = module.s4hana_system.connection_info
}

output "database_info" {
  description = "HANA database details"
  value = {
    hostname   = module.s4hana_system.hana_database.vm_name
    ip_address = module.s4hana_system.hana_database.ip_address
    sid        = var.sap_sid
    instance   = "00"
    memory_gb  = module.s4hana_system.hana_database.resources.memory_gb
    vcpus      = module.s4hana_system.hana_database.resources.vcpus
  }
}

output "application_servers" {
  description = "Application server details"
  value = {
    pas = {
      hostname   = module.s4hana_system.pas_instance.vm_name
      ip_address = module.s4hana_system.pas_instance.ip_address
    }
    aas = [
      for vm in module.s4hana_system.aas_instances : {
        hostname   = vm.vm_name
        ip_address = vm.ip_address
      }
    ]
  }
}

output "ansible_inventory_location" {
  description = "Location of generated Ansible inventory"
  value       = module.s4hana_system.ansible_inventory_path
}

output "deployment_summary" {
  description = "Human-readable deployment summary"
  value = <<-EOT
    ╔══════════════════════════════════════════════════════════════╗
    ║           SAP S/4HANA Deployment Summary                     ║
    ╠══════════════════════════════════════════════════════════════╣
    ║ SAP SID:          ${var.sap_sid}                                          ║
    ║ Environment:      ${var.environment}                                       ║
    ║ Total VMs:        ${length(module.s4hana_system.all_vms)}                                           ║
    ║                                                              ║
    ║ HANA Database:    ${module.s4hana_system.hana_database.ip_address}                       ║
    ║ ASCS:             ${module.s4hana_system.ascs_instance.ip_address}                       ║
    ║ ERS:              ${module.s4hana_system.ers_instance.ip_address}                       ║
    ║ PAS:              ${module.s4hana_system.pas_instance.ip_address}                       ║
    ║ AAS Count:        ${length(module.s4hana_system.aas_instances)}                                           ║
    ║ Web Dispatcher:   ${module.s4hana_system.web_dispatcher.ip_address}                       ║
    ║                                                              ║
    ║ SAP GUI:          ${module.s4hana_system.connection_info.sap_gui_connection}              ║
    ║ Web URL:          ${module.s4hana_system.connection_info.web_url}     ║
    ╚══════════════════════════════════════════════════════════════╝
  EOT
}

