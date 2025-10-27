# ============================================================================
# Terraform SAP on Nutanix - Root Module
# ============================================================================
#
# This root module serves as an orchestration layer for deploying SAP
# workloads on Nutanix infrastructure. It provides data sources for common
# resources and can instantiate SAP-specific modules.
#
# Usage: Uncomment and configure the module blocks below based on your needs
# ============================================================================

# ============================================================================
# Data Sources - Common Resources
# ============================================================================

data "nutanix_cluster" "cluster" {
  name = var.cluster_name
}

data "nutanix_subnet" "subnet" {
  subnet_name = var.subnet_name
}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  # Merge common tags with user-provided tags
  merged_tags = merge(
    var.common_tags,
    var.tags,
    {
      Environment = var.environment
      Landscape   = var.sap_landscape_name
    }
  )

  # Cluster UUID for module consumption
  cluster_uuid = data.nutanix_cluster.cluster.id

  # Subnet UUID for module consumption
  subnet_uuid = data.nutanix_subnet.subnet.id
}

# ============================================================================
# SAP Modules - Uncomment and Configure as Needed
# ============================================================================

# Example: SAP HANA Single Node Deployment
# module "sap_hana_db" {
#   source = "./modules/sap-hana"
#
#   # VM Configuration
#   vm_name      = "${var.sap_landscape_name}-hana-db"
#   cluster_uuid = local.cluster_uuid
#   
#   # SAP HANA Configuration
#   hana_sid             = "HDB"
#   hana_instance_number = "00"
#   
#   # Sizing (following SAP sizing guidelines)
#   memory_gb            = 256
#   num_vcpus            = 32
#   sap_system_size      = "M"
#   
#   # Storage Configuration
#   os_image_name        = "SLES15-SP5-SAP"
#   data_disk_size_gb    = 500
#   data_disk_count      = 4
#   log_disk_size_gb     = 250
#   log_disk_count       = 3
#   shared_disk_size_gb  = 200
#   
#   # Network
#   subnet_uuid          = local.subnet_uuid
#   
#   # Tags
#   tags                 = local.merged_tags
# }

# Example: SAP NetWeaver Application Server
# module "sap_netweaver_pas" {
#   source = "./modules/sap-netweaver"
#
#   # VM Configuration
#   vm_name      = "${var.sap_landscape_name}-netweaver-pas"
#   cluster_uuid = local.cluster_uuid
#   
#   # SAP NetWeaver Configuration
#   sap_sid              = "NPL"
#   instance_number      = "00"
#   instance_type        = "PAS"  # PAS, AAS, ASCS, ERS, WDP
#   
#   # Sizing
#   memory_gb            = 64
#   num_vcpus            = 16
#   
#   # Storage
#   os_image_name        = "SLES15-SP5-SAP"
#   data_disk_size_gb    = 200
#   
#   # Network
#   subnet_uuid          = local.subnet_uuid
#   
#   # Tags
#   tags                 = local.merged_tags
# }

# Example: SAP S/4HANA Distributed System
# module "sap_s4hana" {
#   source = "./modules/sap-s4hana"
#
#   # System Configuration
#   sap_sid              = "S4D"
#   landscape_type       = "distributed"
#   cluster_uuid         = local.cluster_uuid
#   subnet_uuid          = local.subnet_uuid
#   
#   # HANA Database Configuration
#   hana_vm_config = {
#     name       = "${var.sap_landscape_name}-s4d-db"
#     memory_gb  = 512
#     num_vcpus  = 64
#     image_name = "SLES15-SP5-SAP"
#   }
#   
#   # ASCS Instance
#   ascs_vm_config = {
#     name       = "${var.sap_landscape_name}-s4d-ascs"
#     memory_gb  = 32
#     num_vcpus  = 8
#     image_name = "SLES15-SP5-SAP"
#   }
#   
#   # Application Servers
#   app_servers = [
#     {
#       name       = "${var.sap_landscape_name}-s4d-pas"
#       type       = "PAS"
#       memory_gb  = 64
#       num_vcpus  = 16
#       image_name = "SLES15-SP5-SAP"
#     },
#     {
#       name       = "${var.sap_landscape_name}-s4d-aas01"
#       type       = "AAS"
#       memory_gb  = 64
#       num_vcpus  = 16
#       image_name = "SLES15-SP5-SAP"
#     }
#   ]
#   
#   # Tags
#   tags = local.merged_tags
# }

