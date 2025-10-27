# ============================================================================
# Example Variables - SAP S/4HANA Distributed System
# ============================================================================

variable "nutanix_username" {
  description = "Nutanix username"
  type        = string
  sensitive   = true
}

variable "nutanix_password" {
  description = "Nutanix password"
  type        = string
  sensitive   = true
}

variable "nutanix_endpoint" {
  description = "Nutanix Prism Central/Element endpoint"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Nutanix cluster"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, test, prod)"
  type        = string
  default     = "prod"
}

variable "sap_sid" {
  description = "SAP System ID"
  type        = string
  default     = "S4P"
  
  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{2}$", var.sap_sid))
    error_message = "SID must be 3 characters, starting with a letter."
  }
}

variable "ip_base" {
  description = "Base IP address (e.g., 10.10.10) - will append host part. Leave empty for DHCP"
  type        = string
  default     = ""
}

variable "os_image_name" {
  description = "Name of the OS image"
  type        = string
  default     = "SLES15-SP5-SAP"
}

variable "ssh_keys" {
  description = "SSH public keys for access"
  type        = list(string)
  default     = []
}

variable "timezone" {
  description = "System timezone"
  type        = string
  default     = "UTC"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

