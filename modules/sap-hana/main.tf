# ============================================================================
# SAP HANA Module for Nutanix
# ============================================================================
#
# This module deploys SAP HANA VMs on Nutanix following SAP notes:
# - SAP Note 1944799: SAP HANA Guidelines for Nutanix Systems
# - SAP Note 1900823: SAP HANA Storage Requirements (sizing formulas)
# - SAP Note 2205917: OS Settings for SLES 12
# - SAP Note 2684254: OS Settings for SLES 15
# - SAP Note 2015553: SAP on Linux General Prerequisites
#
# Sizing Guidelines: https://www.sap.com/about/benchmark/sizing.sizing-guidelines.html
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
# Data Sources
# ============================================================================

data "nutanix_cluster" "cluster" {
  count        = var.cluster_uuid == "" ? 1 : 0
  cluster_name = var.cluster_name
}

data "nutanix_image" "os_image" {
  image_name = var.os_image_name
}

data "nutanix_subnet" "subnet" {
  count       = var.subnet_uuid == "" ? 1 : 0
  subnet_name = var.subnet_name
}

# ============================================================================
# Local Variables - SAP HANA Configuration
# ============================================================================

locals {
  cluster_uuid = var.cluster_uuid != "" ? var.cluster_uuid : data.nutanix_cluster.cluster[0].id
  subnet_uuid  = var.subnet_uuid != "" ? var.subnet_uuid : data.nutanix_subnet.subnet[0].id

  # SAP HANA T-shirt sizing for virtualized environments
  # Based on SAP sizing guidelines: https://www.sap.com/about/benchmark/sizing.sizing-guidelines.html
  sap_sizing_presets = {
    "XS" = { memory = 64, vcpus = 8, data_disks = 2, log_disks = 2 }
    "S"  = { memory = 128, vcpus = 16, data_disks = 2, log_disks = 2 }
    "M"  = { memory = 256, vcpus = 32, data_disks = 4, log_disks = 4 }
    "L"  = { memory = 512, vcpus = 64, data_disks = 4, log_disks = 4 }
    "XL" = { memory = 1024, vcpus = 96, data_disks = 4, log_disks = 4 }
  }

  # Use preset or custom values
  use_preset      = var.sap_system_size != "custom"
  sizing_config   = local.use_preset ? local.sap_sizing_presets[var.sap_system_size] : null
  actual_memory   = local.use_preset ? local.sizing_config.memory : var.memory_gb
  actual_vcpus    = local.use_preset ? local.sizing_config.vcpus : var.num_vcpus
  actual_data_disks = local.use_preset ? local.sizing_config.data_disks : var.data_disk_count
  actual_log_disks  = local.use_preset ? local.sizing_config.log_disks : var.log_disk_count

  # SAP HANA storage calculations per SAP Note 1900823
  # Data: 1.5x RAM
  data_disk_size_gb = var.data_disk_size_gb > 0 ? var.data_disk_size_gb : ceil((local.actual_memory * 1.5) / local.actual_data_disks)
  
  # Log: 0.5x RAM for systems ≤ 512GB, minimum 512GB for systems > 512GB
  log_total_size_gb = local.actual_memory <= 512 ? (local.actual_memory * 0.5) : 512
  log_disk_size_gb = var.log_disk_size_gb > 0 ? var.log_disk_size_gb : ceil(local.log_total_size_gb / local.actual_log_disks)
  
  # Shared (single-node): MIN(1x RAM, 1 TB)
  shared_disk_size_gb = var.shared_disk_size_gb > 0 ? var.shared_disk_size_gb : min(local.actual_memory, 1024)

  # Backup: typically 2x RAM for data + log
  backup_disk_size_gb = var.backup_disk_size_gb > 0 ? var.backup_disk_size_gb : (local.actual_memory * 2)

  # Convert GB to MiB for Nutanix API
  gb_to_mib = 1024

  # CPU topology optimization - prefer fewer sockets with more cores
  # This improves NUMA locality per SAP recommendations
  num_sockets          = var.num_sockets > 0 ? var.num_sockets : (local.actual_vcpus >= 32 ? 2 : 1)
  num_vcpus_per_socket = ceil(local.actual_vcpus / local.num_sockets)

  # Categories for organization
  categories = merge(
    var.categories,
    {
      "SAP_System_Type" = "HANA"
      "SAP_SID"         = var.hana_sid
    }
  )

  # Cloud-init configuration for guest OS
  cloud_init_enabled = var.cloud_init_config != null
  
  cloud_init_user_data = local.cloud_init_enabled ? templatefile("${path.module}/templates/cloud-init.yaml", {
    hostname                = var.vm_name
    ssh_authorized_keys     = var.cloud_init_config.ssh_authorized_keys
    additional_packages     = var.cloud_init_config.additional_packages
    hana_sid               = var.hana_sid
    hana_instance_number   = var.hana_instance_number
    timezone               = var.cloud_init_config.timezone
  }) : ""
}

# ============================================================================
# SAP HANA Virtual Machine
# ============================================================================

resource "nutanix_virtual_machine" "sap_hana" {
  name         = var.vm_name
  cluster_uuid = local.cluster_uuid

  # CPU Configuration - optimized for SAP HANA
  num_sockets          = local.num_sockets
  num_vcpus_per_socket = local.num_vcpus_per_socket
  
  # Memory Configuration - in MiB
  memory_size_mib = local.actual_memory * local.gb_to_mib

  # Power state
  power_state = var.power_state

  # ============================================================================
  # Disk Configuration per SAP Note 2205917
  # ============================================================================

  # Boot/OS Disk (from image)
  disk_list {
    data_source_reference {
      kind = "image"
      uuid = data.nutanix_image.os_image.id
    }
    disk_size_mib = var.os_disk_size_gb * local.gb_to_mib
    device_properties {
      device_type = "DISK"
      disk_address {
        device_index = 0
        adapter_type = "SCSI"
      }
    }
  }

  # /hana/data disks - striped for performance
  dynamic "disk_list" {
    for_each = range(local.actual_data_disks)
    content {
      disk_size_mib = local.data_disk_size_gb * local.gb_to_mib
      device_properties {
        device_type = "DISK"
        disk_address {
          device_index = disk_list.value + 1
          adapter_type = "SCSI"
        }
      }
    }
  }

  # /hana/log disks - separate for better I/O
  dynamic "disk_list" {
    for_each = range(local.actual_log_disks)
    content {
      disk_size_mib = local.log_disk_size_gb * local.gb_to_mib
      device_properties {
        device_type = "DISK"
        disk_address {
          device_index = disk_list.value + 1 + local.actual_data_disks
          adapter_type = "SCSI"
        }
      }
    }
  }

  # /hana/shared disk
  disk_list {
    disk_size_mib = local.shared_disk_size_gb * local.gb_to_mib
    device_properties {
      device_type = "DISK"
      disk_address {
        device_index = 1 + local.actual_data_disks + local.actual_log_disks
        adapter_type = "SCSI"
      }
    }
  }

  # /hana/backup disk (optional)
  dynamic "disk_list" {
    for_each = var.enable_backup_disk ? [1] : []
    content {
      disk_size_mib = local.backup_disk_size_gb * local.gb_to_mib
      device_properties {
        device_type = "DISK"
        disk_address {
          device_index = 2 + local.actual_data_disks + local.actual_log_disks
          adapter_type = "SCSI"
        }
      }
    }
  }

  # ============================================================================
  # Network Configuration
  # ============================================================================

  nic_list {
    subnet_uuid = local.subnet_uuid
    
    # Static IP configuration (optional)
    ip_endpoint_list {
      ip   = var.ip_address
      type = var.ip_address != "" ? "ASSIGNED" : "LEARNED"
    }
  }

  # Additional network interfaces for dedicated HANA networks
  dynamic "nic_list" {
    for_each = var.additional_network_interfaces
    content {
      subnet_uuid = nic_list.value.subnet_uuid
      ip_endpoint_list {
        ip   = nic_list.value.ip_address
        type = nic_list.value.ip_address != "" ? "ASSIGNED" : "LEARNED"
      }
    }
  }

  # ============================================================================
  # Guest Customization
  # ============================================================================

  dynamic "guest_customization_cloud_init_user_data" {
    for_each = local.cloud_init_enabled ? [1] : []
    content {
      user_data = base64encode(local.cloud_init_user_data)
    }
  }

  # ============================================================================
  # VM Categories and Metadata
  # ============================================================================

  categories {
    name  = "SAP_System_Type"
    value = "HANA"
  }

  categories {
    name  = "SAP_SID"
    value = var.hana_sid
  }

  dynamic "categories" {
    for_each = local.categories
    content {
      name  = categories.key
      value = categories.value
    }
  }

  # ============================================================================
  # Hardware Optimizations for SAP HANA
  # ============================================================================

  # Enable memory hot add (useful for scaling)
  enable_memory_hotplug = var.enable_memory_hotplug

  # NUMA configuration - implicit through socket configuration
  # Nutanix automatically optimizes NUMA for SAP workloads

  # Machine type
  machine_type = var.machine_type

  # VM description
  description = "SAP HANA ${var.hana_sid} - Instance ${var.hana_instance_number} - Size: ${var.sap_system_size}"
}

# ============================================================================
# Protection Policy Assignment (Backup)
# ============================================================================

resource "nutanix_protection_rule" "hana_backup" {
  count = var.protection_policy_name != "" ? 1 : 0

  name        = "${var.vm_name}-backup-rule"
  description = "Backup policy for SAP HANA ${var.hana_sid}"

  categories_filter {
    type   = "CATEGORIES_MATCH_ANY"
    kind_list = ["vm"]
    
    params {
      name   = "SAP_SID"
      values = [var.hana_sid]
    }
  }

  availability_zone_connectivity_list {
    destination_availability_zone_index = 0
    source_availability_zone_index      = 0
  }

  ordered_availability_zone_list {
    availability_zone_url = "local"
    cluster_uuid          = local.cluster_uuid
  }
}

