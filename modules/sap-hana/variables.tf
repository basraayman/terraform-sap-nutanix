# ============================================================================
# SAP HANA Module Variables
# ============================================================================

# ============================================================================
# Infrastructure Configuration
# ============================================================================

variable "cluster_name" {
  description = "Name of the Nutanix cluster (used if cluster_uuid not provided)"
  type        = string
  default     = ""
}

variable "cluster_uuid" {
  description = "UUID of the Nutanix cluster"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Name of the subnet (used if subnet_uuid not provided)"
  type        = string
  default     = ""
}

variable "subnet_uuid" {
  description = "UUID of the subnet for VM networking"
  type        = string
  default     = ""
}

# ============================================================================
# VM Basic Configuration
# ============================================================================

variable "vm_name" {
  description = "Name of the SAP HANA VM"
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.vm_name))
    error_message = "VM name must contain only alphanumeric characters and hyphens."
  }
}

variable "power_state" {
  description = "Power state of the VM after creation"
  type        = string
  default     = "ON"
  validation {
    condition     = contains(["ON", "OFF"], var.power_state)
    error_message = "Power state must be ON or OFF."
  }
}

variable "machine_type" {
  description = "Machine type for the VM"
  type        = string
  default     = "PC"
}

# ============================================================================
# SAP HANA Configuration
# ============================================================================

variable "hana_sid" {
  description = "SAP HANA System ID (3 characters)"
  type        = string
  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{2}$", var.hana_sid))
    error_message = "SAP HANA SID must be 3 characters, starting with a letter."
  }
}

variable "hana_instance_number" {
  description = "SAP HANA instance number (00-99)"
  type        = string
  default     = "00"
  validation {
    condition     = can(regex("^[0-9]{2}$", var.hana_instance_number))
    error_message = "Instance number must be two digits (00-99)."
  }
}

variable "hana_deployment_type" {
  description = "HANA deployment type: single_node, scale_out, or system_replication"
  type        = string
  default     = "single_node"
  validation {
    condition     = contains(["single_node", "scale_out", "system_replication"], var.hana_deployment_type)
    error_message = "Deployment type must be single_node, scale_out, or system_replication."
  }
}

# ============================================================================
# Sizing Configuration
# ============================================================================

variable "sap_system_size" {
  description = "SAP system size preset (XS, S, M, L, XL) or 'custom' for manual configuration"
  type        = string
  default     = "M"
  validation {
    condition     = contains(["XS", "S", "M", "L", "XL", "custom"], var.sap_system_size)
    error_message = "System size must be XS, S, M, L, XL, or custom."
  }
}

variable "memory_gb" {
  description = "Memory in GB (used when sap_system_size is 'custom')"
  type        = number
  default     = 256
  validation {
    condition     = var.memory_gb >= 64 && var.memory_gb <= 12288
    error_message = "Memory must be between 64 GB and 12 TB (12288 GB)."
  }
}

variable "num_vcpus" {
  description = "Number of vCPUs (used when sap_system_size is 'custom')"
  type        = number
  default     = 32
  validation {
    condition     = var.num_vcpus >= 4 && var.num_vcpus <= 256
    error_message = "vCPUs must be between 4 and 256."
  }
}

variable "num_sockets" {
  description = "Number of CPU sockets (0 = auto-calculate for NUMA optimization)"
  type        = number
  default     = 0
}

# ============================================================================
# Storage Configuration - OS
# ============================================================================

variable "os_image_name" {
  description = "Name of the OS image to use"
  type        = string
}

variable "os_disk_size_gb" {
  description = "OS disk size in GB"
  type        = number
  default     = 100
}

# ============================================================================
# Storage Configuration - HANA Data
# ============================================================================

variable "data_disk_count" {
  description = "Number of data disks for /hana/data (used when sap_system_size is 'custom')"
  type        = number
  default     = 4
  validation {
    condition     = var.data_disk_count >= 1 && var.data_disk_count <= 8
    error_message = "Data disk count must be between 1 and 8."
  }
}

variable "data_disk_size_gb" {
  description = "Size of each data disk in GB (0 = auto-calculate based on RAM)"
  type        = number
  default     = 0
}

# ============================================================================
# Storage Configuration - HANA Log
# ============================================================================

variable "log_disk_count" {
  description = "Number of log disks for /hana/log (used when sap_system_size is 'custom')"
  type        = number
  default     = 3
  validation {
    condition     = var.log_disk_count >= 1 && var.log_disk_count <= 4
    error_message = "Log disk count must be between 1 and 4."
  }
}

variable "log_disk_size_gb" {
  description = "Size of each log disk in GB (0 = auto-calculate based on RAM)"
  type        = number
  default     = 0
}

# ============================================================================
# Storage Configuration - HANA Shared and Backup
# ============================================================================

variable "shared_disk_size_gb" {
  description = "Size of /hana/shared disk in GB (0 = auto-calculate based on RAM)"
  type        = number
  default     = 0
}

variable "enable_backup_disk" {
  description = "Add a dedicated backup disk for /hana/backup"
  type        = bool
  default     = true
}

variable "backup_disk_size_gb" {
  description = "Size of backup disk in GB (0 = auto-calculate as 2x RAM)"
  type        = number
  default     = 0
}

# ============================================================================
# Network Configuration
# ============================================================================

variable "ip_address" {
  description = "Static IP address for the VM (empty for DHCP)"
  type        = string
  default     = ""
}

variable "additional_network_interfaces" {
  description = "Additional network interfaces for dedicated HANA networks"
  type = list(object({
    subnet_uuid = string
    ip_address  = string
  }))
  default = []
}

# ============================================================================
# Cloud-Init / Guest Customization
# ============================================================================

variable "cloud_init_config" {
  description = "Cloud-init configuration for guest OS customization"
  type = object({
    ssh_authorized_keys = list(string)
    additional_packages = list(string)
    timezone            = string
  })
  default = null
}

# ============================================================================
# Advanced Configuration
# ============================================================================

variable "enable_memory_hotplug" {
  description = "Enable memory hot-add capability"
  type        = bool
  default     = false
}

variable "protection_policy_name" {
  description = "Name of protection policy for VM backup"
  type        = string
  default     = ""
}

variable "categories" {
  description = "Additional Nutanix categories to assign to the VM"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

