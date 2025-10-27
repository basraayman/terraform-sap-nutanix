# ============================================================================
# SAP S/4HANA Module for Nutanix
# ============================================================================
#
# This module orchestrates complete SAP S/4HANA system deployments including:
# - SAP HANA database
# - Central Services (ASCS/ERS)
# - Application servers (PAS/AAS)
# - Optional Web Dispatcher
#
# Supports both converged and distributed deployments
#
# ============================================================================

terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "~> 1.9.0"
    }
  }
}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Deployment mode validation
  is_converged    = var.landscape_type == "converged"
  is_distributed  = var.landscape_type == "distributed"
  
  # HANA and NetWeaver run on same VM in converged mode
  hana_vm_name    = local.is_converged ? "${var.sap_sid}-converged" : "${var.sap_sid}-db"
  
  # Calculate total VMs
  total_vms = (local.is_distributed ? 1 : 0) + # HANA DB (distributed only)
              (var.deploy_ascs ? 1 : 0) +      # ASCS
              (var.deploy_ers ? 1 : 0) +       # ERS
              1 +                               # PAS (always)
              length(var.additional_app_servers) + # AAS
              (var.deploy_web_dispatcher ? 1 : 0)  # Web Dispatcher

  # Common tags
  common_tags = merge(
    var.tags,
    {
      SAP_System = var.sap_sid
      Landscape  = var.landscape_type
    }
  )
}

# ============================================================================
# SAP HANA Database
# ============================================================================

module "hana_database" {
  source = "../sap-hana"

  # VM Configuration
  vm_name      = local.hana_vm_name
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP HANA Configuration
  hana_sid             = var.sap_sid
  hana_instance_number = var.hana_instance_number
  hana_deployment_type = "single_node"

  # Sizing
  sap_system_size      = lookup(var.hana_vm_config, "system_size", "custom")
  memory_gb            = var.hana_vm_config.memory_gb
  num_vcpus            = var.hana_vm_config.num_vcpus
  
  # Storage
  os_image_name        = var.hana_vm_config.image_name
  data_disk_count      = lookup(var.hana_vm_config, "data_disk_count", 4)
  log_disk_count       = lookup(var.hana_vm_config, "log_disk_count", 3)
  enable_backup_disk   = lookup(var.hana_vm_config, "enable_backup_disk", true)

  # Network
  ip_address           = lookup(var.hana_vm_config, "ip_address", "")

  # Cloud-init
  cloud_init_config    = var.cloud_init_config

  # Categories
  categories           = local.common_tags
  tags                 = var.tags
}

# ============================================================================
# ASCS Instance (ABAP Central Services)
# ============================================================================

module "ascs_instance" {
  count  = var.deploy_ascs ? 1 : 0
  source = "../sap-netweaver"

  # VM Configuration
  vm_name      = "${var.sap_sid}-ascs"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = var.sap_sid
  instance_number  = var.ascs_instance_number
  instance_type    = "ASCS"
  stack_type       = var.stack_type

  # Sizing
  memory_gb = lookup(var.ascs_vm_config, "memory_gb", 32)
  num_vcpus = lookup(var.ascs_vm_config, "num_vcpus", 8)

  # Storage
  os_image_name        = lookup(var.ascs_vm_config, "image_name", var.hana_vm_config.image_name)
  os_disk_size_gb      = lookup(var.ascs_vm_config, "os_disk_size_gb", 100)
  usrsap_disk_size_gb  = lookup(var.ascs_vm_config, "usrsap_disk_size_gb", 100)
  sapmnt_disk_size_gb  = lookup(var.ascs_vm_config, "sapmnt_disk_size_gb", 200)

  # Network
  ip_address = lookup(var.ascs_vm_config, "ip_address", "")

  # Cloud-init
  cloud_init_config = var.cloud_init_config

  # Categories
  categories = local.common_tags
  tags       = var.tags
}

# ============================================================================
# ERS Instance (Enqueue Replication Server)
# ============================================================================

module "ers_instance" {
  count  = var.deploy_ers ? 1 : 0
  source = "../sap-netweaver"

  # VM Configuration
  vm_name      = "${var.sap_sid}-ers"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = var.sap_sid
  instance_number  = var.ers_instance_number
  instance_type    = "ERS"
  stack_type       = var.stack_type

  # Sizing
  memory_gb = lookup(var.ers_vm_config, "memory_gb", 32)
  num_vcpus = lookup(var.ers_vm_config, "num_vcpus", 8)

  # Storage
  os_image_name        = lookup(var.ers_vm_config, "image_name", var.hana_vm_config.image_name)
  os_disk_size_gb      = lookup(var.ers_vm_config, "os_disk_size_gb", 100)
  usrsap_disk_size_gb  = lookup(var.ers_vm_config, "usrsap_disk_size_gb", 50)

  # Network
  ip_address = lookup(var.ers_vm_config, "ip_address", "")

  # Cloud-init
  cloud_init_config = var.cloud_init_config

  # Categories
  categories = local.common_tags
  tags       = var.tags

  depends_on = [module.ascs_instance]
}

# ============================================================================
# PAS Instance (Primary Application Server)
# ============================================================================

module "pas_instance" {
  source = "../sap-netweaver"

  # VM Configuration
  vm_name      = "${var.sap_sid}-pas"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = var.sap_sid
  instance_number  = var.pas_instance_number
  instance_type    = "PAS"
  stack_type       = var.stack_type

  # Sizing
  memory_gb = var.pas_vm_config.memory_gb
  num_vcpus = var.pas_vm_config.num_vcpus

  # Storage
  os_image_name        = lookup(var.pas_vm_config, "image_name", var.hana_vm_config.image_name)
  os_disk_size_gb      = lookup(var.pas_vm_config, "os_disk_size_gb", 100)
  usrsap_disk_size_gb  = lookup(var.pas_vm_config, "usrsap_disk_size_gb", 150)

  # Network
  ip_address = lookup(var.pas_vm_config, "ip_address", "")

  # Cloud-init
  cloud_init_config = var.cloud_init_config

  # Categories
  categories = local.common_tags
  tags       = var.tags

  depends_on = [module.hana_database, module.ascs_instance]
}

# ============================================================================
# AAS Instances (Additional Application Servers)
# ============================================================================

module "aas_instances" {
  count  = length(var.additional_app_servers)
  source = "../sap-netweaver"

  # VM Configuration
  vm_name      = "${var.sap_sid}-aas${format("%02d", count.index + 1)}"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = var.sap_sid
  instance_number  = format("%02d", var.pas_instance_number + count.index + 1)
  instance_type    = "AAS"
  stack_type       = var.stack_type

  # Sizing
  memory_gb = var.additional_app_servers[count.index].memory_gb
  num_vcpus = var.additional_app_servers[count.index].num_vcpus

  # Storage
  os_image_name        = lookup(var.additional_app_servers[count.index], "image_name", var.hana_vm_config.image_name)
  os_disk_size_gb      = lookup(var.additional_app_servers[count.index], "os_disk_size_gb", 100)
  usrsap_disk_size_gb  = lookup(var.additional_app_servers[count.index], "usrsap_disk_size_gb", 100)

  # Network
  ip_address = lookup(var.additional_app_servers[count.index], "ip_address", "")

  # Cloud-init
  cloud_init_config = var.cloud_init_config

  # Categories
  categories = local.common_tags
  tags       = var.tags

  depends_on = [module.pas_instance]
}

# ============================================================================
# Web Dispatcher (Optional)
# ============================================================================

module "web_dispatcher" {
  count  = var.deploy_web_dispatcher ? 1 : 0
  source = "../sap-netweaver"

  # VM Configuration
  vm_name      = "${var.sap_sid}-wdp"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = var.sap_sid
  instance_number  = var.web_dispatcher_instance_number
  instance_type    = "WDP"
  stack_type       = var.stack_type

  # Sizing
  memory_gb = lookup(var.web_dispatcher_vm_config, "memory_gb", 16)
  num_vcpus = lookup(var.web_dispatcher_vm_config, "num_vcpus", 8)

  # Storage
  os_image_name        = lookup(var.web_dispatcher_vm_config, "image_name", var.hana_vm_config.image_name)
  os_disk_size_gb      = lookup(var.web_dispatcher_vm_config, "os_disk_size_gb", 100)
  usrsap_disk_size_gb  = lookup(var.web_dispatcher_vm_config, "usrsap_disk_size_gb", 50)

  # Network
  ip_address = lookup(var.web_dispatcher_vm_config, "ip_address", "")

  # Cloud-init
  cloud_init_config = var.cloud_init_config

  # Categories
  categories = local.common_tags
  tags       = var.tags

  depends_on = [module.pas_instance]
}

# ============================================================================
# Ansible Inventory Generation
# ============================================================================

resource "local_file" "ansible_inventory" {
  count    = var.generate_ansible_inventory ? 1 : 0
  filename = var.ansible_inventory_path

  content = templatefile("${path.module}/templates/ansible-inventory.tftpl", {
    sap_sid               = var.sap_sid
    ansible_user          = var.ansible_user
    
    hana_host             = module.hana_database.ip_address
    hana_hostname         = module.hana_database.vm_name
    
    ascs_host             = var.deploy_ascs ? module.ascs_instance[0].ip_address : ""
    ascs_hostname         = var.deploy_ascs ? module.ascs_instance[0].vm_name : ""
    
    ers_host              = var.deploy_ers ? module.ers_instance[0].ip_address : ""
    ers_hostname          = var.deploy_ers ? module.ers_instance[0].vm_name : ""
    
    pas_host              = module.pas_instance.ip_address
    pas_hostname          = module.pas_instance.vm_name
    
    aas_hosts             = [for vm in module.aas_instances : vm.ip_address]
    aas_hostnames         = [for vm in module.aas_instances : vm.vm_name]
    
    wdp_host              = var.deploy_web_dispatcher ? module.web_dispatcher[0].ip_address : ""
    wdp_hostname          = var.deploy_web_dispatcher ? module.web_dispatcher[0].vm_name : ""
  })
}

