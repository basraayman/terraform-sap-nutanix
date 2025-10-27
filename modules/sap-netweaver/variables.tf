# ============================================================================
# SAP NetWeaver Module Variables
# ============================================================================

# ============================================================================
# Infrastructure Configuration
# ============================================================================

variable "cluster_name" {
  description = "Name of the Nutanix cluster"
  type        = string
  default     = ""
}

variable "cluster_uuid" {
  description = "UUID of the Nutanix cluster"
  type        = string
  default     = ""
}

variable "subnet_name" {
  description = "Name of the subnet"
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
  description = "Name of the SAP NetWeaver VM"
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
# SAP NetWeaver Configuration
# ============================================================================

variable "sap_sid" {
  description = "SAP System ID (3 characters)"
  type        = string
  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{2}$", var.sap_sid))
    error_message = "SAP SID must be 3 characters, starting with a letter."
  }
}

variable "instance_number" {
  description = "SAP instance number (00-99)"
  type        = string
  default     = "00"
  validation {
    condition     = can(regex("^[0-9]{2}$", var.instance_number))
    error_message = "Instance number must be two digits (00-99)."
  }
}

variable "instance_type" {
  description = "Type of NetWeaver instance: PAS, AAS, ASCS, ERS, WDP"
  type        = string
  validation {
    condition     = contains(["PAS", "AAS", "ASCS", "ERS", "WDP"], var.instance_type)
    error_message = "Instance type must be PAS, AAS, ASCS, ERS, or WDP."
  }
}

variable "stack_type" {
  description = "Stack type: ABAP, JAVA, or DUAL"
  type        = string
  default     = "ABAP"
  validation {
    condition     = contains(["ABAP", "JAVA", "DUAL"], var.stack_type)
    error_message = "Stack type must be ABAP, JAVA, or DUAL."
  }
}

# ============================================================================
# Sizing Configuration
# ============================================================================

variable "memory_gb" {
  description = "Memory in GB"
  type        = number
  validation {
    condition     = var.memory_gb >= 8 && var.memory_gb <= 1024
    error_message = "Memory must be between 8 GB and 1 TB."
  }
}

variable "num_vcpus" {
  description = "Number of vCPUs"
  type        = number
  validation {
    condition     = var.num_vcpus >= 2 && var.num_vcpus <= 128
    error_message = "vCPUs must be between 2 and 128."
  }
}

variable "num_sockets" {
  description = "Number of CPU sockets (0 = auto-calculate)"
  type        = number
  default     = 0
}

# ============================================================================
# Storage Configuration
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

variable "usrsap_disk_size_gb" {
  description = "Size of /usr/sap disk in GB"
  type        = number
  default     = 100
}

variable "sapmnt_disk_size_gb" {
  description = "Size of /sapmnt disk in GB (0 to skip, typically for ASCS)"
  type        = number
  default     = 0
}

variable "additional_data_disks" {
  description = "Additional data disks for the VM"
  type = list(object({
    size_gb      = number
    device_index = number
  }))
  default = []
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
  description = "Additional network interfaces"
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

