# ============================================================================
# Example: SAP HANA Single Node Deployment
# ============================================================================
#
# This example demonstrates deploying a single-node SAP HANA database
# on Nutanix infrastructure using the sap-hana module.
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
# SAP HANA Database - Production Size
# ============================================================================

module "hana_database" {
  source = "../../modules/sap-hana"

  # VM Configuration
  vm_name      = "${var.environment}-${var.hana_sid}-db01"
  cluster_uuid = data.nutanix_cluster.cluster.id
  subnet_uuid  = data.nutanix_subnet.subnet.id

  # SAP HANA Configuration
  hana_sid             = var.hana_sid
  hana_instance_number = "00"
  hana_deployment_type = "single_node"

  # Sizing - Use preset M size (256 GB RAM, 32 vCPUs)
  sap_system_size = "M"

  # OS Configuration
  os_image_name = var.os_image_name

  # Storage - Let module calculate based on RAM
  # Will create:
  # - OS: 100 GB
  # - Data: 4 x 64 GB = 256 GB (striped)
  # - Log: 3 x 43 GB = 129 GB (striped)
  # - Shared: 256 GB
  # - Backup: 512 GB
  enable_backup_disk = true

  # Network - Static IP
  ip_address = var.hana_ip_address

  # Cloud-init Configuration
  cloud_init_config = {
    ssh_authorized_keys = var.ssh_keys
    additional_packages = [
      "tuned-profiles-sap-hana",
      "sapconf",
      "resource-agents-sap-hana",
    ]
    timezone = var.timezone
  }

  # Categories for organization
  categories = {
    Environment = var.environment
    Application = "SAP-HANA"
    Owner       = var.owner
  }

  tags = var.tags
}

# ============================================================================
# Outputs
# ============================================================================

output "hana_vm_details" {
  description = "SAP HANA VM details"
  value = {
    name       = module.hana_database.vm_name
    uuid       = module.hana_database.vm_uuid
    ip_address = module.hana_database.ip_address
  }
}

output "hana_configuration" {
  description = "SAP HANA configuration"
  value       = module.hana_database.hana_configuration
}

output "hana_resources" {
  description = "VM resource allocation"
  value       = module.hana_database.vm_resources
}

output "hana_storage" {
  description = "Storage configuration"
  value       = module.hana_database.storage_configuration
}

output "connection_info" {
  description = "Connection information"
  value = {
    hostname    = module.hana_database.vm_name
    ip_address  = module.hana_database.ip_address
    sid         = var.hana_sid
    instance    = "00"
    jdbc_url    = "jdbc:sap://${module.hana_database.ip_address}:30015"
  }
}

output "ansible_host_vars" {
  description = "Ansible host variables"
  value       = module.hana_database.ansible_host_vars
}

