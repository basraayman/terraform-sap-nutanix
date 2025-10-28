# ============================================================================
# SAP NetWeaver Module for Nutanix
# ============================================================================
#
# This module deploys SAP NetWeaver application servers on Nutanix 
# infrastructure following SAP best practices.
#
# Supports: PAS, AAS, ASCS, ERS, Web Dispatcher
#
# SAP Notes:
# - SAP Note 2015553: SAP on Linux General Prerequisites
# - SAP Note 1928533: SAP Applications on Linux
# - SAP Note 2369910: SAP Software on Linux (sizing)
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
  count = var.cluster_uuid == "" ? 1 : 0
  name  = var.cluster_name
}

data "nutanix_image" "os_image" {
  image_name = var.os_image_name
}

data "nutanix_subnet" "subnet" {
  count       = var.subnet_uuid == "" ? 1 : 0
  subnet_name = var.subnet_name
}

# ============================================================================
# Local Variables
# ============================================================================

locals {
  cluster_uuid = var.cluster_uuid != "" ? var.cluster_uuid : data.nutanix_cluster.cluster[0].id
  subnet_uuid  = var.subnet_uuid != "" ? var.subnet_uuid : data.nutanix_subnet.subnet[0].id

  # Instance type configurations
  instance_type_defaults = {
    "PAS" = {  # Primary Application Server
      min_memory    = 32
      min_vcpus     = 8
      recommended_memory = 64
      recommended_vcpus  = 16
    }
    "AAS" = {  # Additional Application Server
      min_memory    = 32
      min_vcpus     = 8
      recommended_memory = 64
      recommended_vcpus  = 16
    }
    "ASCS" = {  # ABAP Central Services
      min_memory    = 16
      min_vcpus     = 4
      recommended_memory = 32
      recommended_vcpus  = 8
    }
    "ERS" = {  # Enqueue Replication Server
      min_memory    = 16
      min_vcpus     = 4
      recommended_memory = 32
      recommended_vcpus  = 8
    }
    "WDP" = {  # Web Dispatcher
      min_memory    = 8
      min_vcpus     = 4
      recommended_memory = 16
      recommended_vcpus  = 8
    }
  }

  instance_config = local.instance_type_defaults[var.instance_type]

  # Convert GB to MiB
  gb_to_mib = 1024

  # CPU topology
  num_sockets          = var.num_sockets > 0 ? var.num_sockets : (var.num_vcpus >= 16 ? 2 : 1)
  num_vcpus_per_socket = ceil(var.num_vcpus / local.num_sockets)

  # Categories
  categories = merge(
    var.categories,
    {
      "SAP_System_Type" = "NetWeaver"
      "SAP_SID"         = var.sap_sid
      "SAP_Instance_Type" = var.instance_type
    }
  )

  # Cloud-init
  cloud_init_enabled = var.cloud_init_config != null
  
  cloud_init_user_data = local.cloud_init_enabled ? templatefile("${path.module}/templates/cloud-init.yaml", {
    hostname                = var.vm_name
    ssh_authorized_keys     = var.cloud_init_config.ssh_authorized_keys
    additional_packages     = var.cloud_init_config.additional_packages
    sap_sid                 = var.sap_sid
    instance_number         = var.instance_number
    instance_type           = var.instance_type
    timezone                = var.cloud_init_config.timezone
  }) : ""
}

# ============================================================================
# SAP NetWeaver Virtual Machine
# ============================================================================

resource "nutanix_virtual_machine" "sap_netweaver" {
  name         = var.vm_name
  cluster_uuid = local.cluster_uuid

  # CPU Configuration
  num_sockets          = local.num_sockets
  num_vcpus_per_socket = local.num_vcpus_per_socket
  
  # Memory Configuration - in MiB
  memory_size_mib = var.memory_gb * local.gb_to_mib

  # Power state
  power_state = var.power_state

  # ============================================================================
  # Disk Configuration
  # ============================================================================

  # Boot/OS Disk (from image)
  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = data.nutanix_image.os_image.id
    }
    disk_size_mib = var.os_disk_size_gb * local.gb_to_mib
    device_properties {
      device_type  = "DISK"
      disk_address = {
        device_index = 0
        adapter_type = "SCSI"
      }
    }
  }

  # /usr/sap disk
  disk_list {
    disk_size_mib = var.usrsap_disk_size_gb * local.gb_to_mib
    device_properties {
      device_type  = "DISK"
      disk_address = {
        device_index = 1
        adapter_type = "SCSI"
      }
    }
  }

  # /sapmnt disk (typically for ASCS)
  dynamic "disk_list" {
    for_each = var.sapmnt_disk_size_gb > 0 ? [1] : []
    content {
      disk_size_mib = var.sapmnt_disk_size_gb * local.gb_to_mib
      device_properties {
        device_type  = "DISK"
        disk_address = {
          device_index = 2
          adapter_type = "SCSI"
        }
      }
    }
  }

  # Additional data disks
  dynamic "disk_list" {
    for_each = var.additional_data_disks
    content {
      disk_size_mib = disk_list.value.size_gb * local.gb_to_mib
      device_properties {
        device_type  = "DISK"
        disk_address = {
          device_index = disk_list.value.device_index
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

  # Additional network interfaces
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
    value = "NetWeaver"
  }

  categories {
    name  = "SAP_SID"
    value = var.sap_sid
  }

  categories {
    name  = "SAP_Instance_Type"
    value = var.instance_type
  }

  dynamic "categories" {
    for_each = local.categories
    content {
      name  = categories.key
      value = categories.value
    }
  }

  # Machine type
  machine_type = var.machine_type

  # VM description
  description = "SAP NetWeaver ${var.sap_sid} - ${var.instance_type} Instance ${var.instance_number}"
}

