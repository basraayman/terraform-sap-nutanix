# ============================================================================
# Example Variables - SAP HANA Single Node
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

variable "hana_sid" {
  description = "SAP HANA System ID"
  type        = string
  default     = "HDB"
  
  validation {
    condition     = can(regex("^[A-Z][A-Z0-9]{2}$", var.hana_sid))
    error_message = "SID must be 3 characters, starting with a letter."
  }
}

variable "hana_ip_address" {
  description = "Static IP address for HANA database"
  type        = string
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

variable "owner" {
  description = "Owner of the resources"
  type        = string
  default     = "SAP-Basis-Team"
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

