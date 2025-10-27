# ============================================================================
# SAP S/4HANA Module Variables
# ============================================================================

# ============================================================================
# Infrastructure Configuration
# ============================================================================

variable "cluster_uuid" {
  description = "UUID of the Nutanix cluster"
  type        = string
}

variable "subnet_uuid" {
  description = "UUID of the subnet for VM networking"
  type        = string
}

# ============================================================================
# SAP System Configuration
# ============================================================================

variable "sap_sid" {
  description = "SAP System ID (3 characters)"
  type        = string
  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{2}$", var.sap_sid))
    error_message = "SAP SID must be 3 characters, starting with a letter."
  }
}

variable "landscape_type" {
  description = "Landscape type: converged (DB+App on same VM) or distributed (separate VMs)"
  type        = string
  default     = "distributed"
  validation {
    condition     = contains(["converged", "distributed"], var.landscape_type)
    error_message = "Landscape type must be 'converged' or 'distributed'."
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
# HANA Database Configuration
# ============================================================================

variable "hana_vm_config" {
  description = "SAP HANA database VM configuration"
  type = object({
    memory_gb         = number
    num_vcpus         = number
    image_name        = string
    system_size       = optional(string, "custom")
    data_disk_count   = optional(number, 4)
    log_disk_count    = optional(number, 3)
    enable_backup_disk = optional(bool, true)
    ip_address        = optional(string, "")
  })
}

variable "hana_instance_number" {
  description = "HANA instance number"
  type        = string
  default     = "00"
}

# ============================================================================
# ASCS Configuration
# ============================================================================

variable "deploy_ascs" {
  description = "Deploy ASCS instance"
  type        = bool
  default     = true
}

variable "ascs_vm_config" {
  description = "ASCS VM configuration"
  type = object({
    memory_gb          = optional(number, 32)
    num_vcpus          = optional(number, 8)
    image_name         = optional(string, "")
    os_disk_size_gb    = optional(number, 100)
    usrsap_disk_size_gb = optional(number, 100)
    sapmnt_disk_size_gb = optional(number, 200)
    ip_address         = optional(string, "")
  })
  default = {}
}

variable "ascs_instance_number" {
  description = "ASCS instance number"
  type        = string
  default     = "01"
}

# ============================================================================
# ERS Configuration
# ============================================================================

variable "deploy_ers" {
  description = "Deploy ERS instance (for high availability)"
  type        = bool
  default     = false
}

variable "ers_vm_config" {
  description = "ERS VM configuration"
  type = object({
    memory_gb          = optional(number, 32)
    num_vcpus          = optional(number, 8)
    image_name         = optional(string, "")
    os_disk_size_gb    = optional(number, 100)
    usrsap_disk_size_gb = optional(number, 50)
    ip_address         = optional(string, "")
  })
  default = {}
}

variable "ers_instance_number" {
  description = "ERS instance number"
  type        = string
  default     = "02"
}

# ============================================================================
# PAS Configuration
# ============================================================================

variable "pas_vm_config" {
  description = "Primary Application Server VM configuration"
  type = object({
    memory_gb          = number
    num_vcpus          = number
    image_name         = optional(string, "")
    os_disk_size_gb    = optional(number, 100)
    usrsap_disk_size_gb = optional(number, 150)
    ip_address         = optional(string, "")
  })
}

variable "pas_instance_number" {
  description = "PAS instance number"
  type        = string
  default     = "00"
}

# ============================================================================
# Additional Application Servers
# ============================================================================

variable "additional_app_servers" {
  description = "Additional application servers (AAS) configuration"
  type = list(object({
    memory_gb          = number
    num_vcpus          = number
    image_name         = optional(string, "")
    os_disk_size_gb    = optional(number, 100)
    usrsap_disk_size_gb = optional(number, 100)
    ip_address         = optional(string, "")
  }))
  default = []
}

# ============================================================================
# Web Dispatcher Configuration
# ============================================================================

variable "deploy_web_dispatcher" {
  description = "Deploy SAP Web Dispatcher"
  type        = bool
  default     = false
}

variable "web_dispatcher_vm_config" {
  description = "Web Dispatcher VM configuration"
  type = object({
    memory_gb          = optional(number, 16)
    num_vcpus          = optional(number, 8)
    image_name         = optional(string, "")
    os_disk_size_gb    = optional(number, 100)
    usrsap_disk_size_gb = optional(number, 50)
    ip_address         = optional(string, "")
  })
  default = {}
}

variable "web_dispatcher_instance_number" {
  description = "Web Dispatcher instance number"
  type        = string
  default     = "80"
}

# ============================================================================
# Cloud-Init / Guest Customization
# ============================================================================

variable "cloud_init_config" {
  description = "Cloud-init configuration for all VMs"
  type = object({
    ssh_authorized_keys = list(string)
    additional_packages = list(string)
    timezone            = string
  })
  default = null
}

# ============================================================================
# Ansible Integration
# ============================================================================

variable "generate_ansible_inventory" {
  description = "Generate Ansible inventory file"
  type        = bool
  default     = true
}

variable "ansible_inventory_path" {
  description = "Path to write Ansible inventory"
  type        = string
  default     = "./ansible/inventory/hosts"
}

variable "ansible_user" {
  description = "SSH user for Ansible"
  type        = string
  default     = "root"
}

# ============================================================================
# Tagging and Organization
# ============================================================================

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

