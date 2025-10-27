# ============================================================================
# Nutanix Provider Configuration Variables
# ============================================================================

variable "nutanix_username" {
  description = "Nutanix Prism Central/Element username"
  type        = string
  sensitive   = true
}

variable "nutanix_password" {
  description = "Nutanix Prism Central/Element password"
  type        = string
  sensitive   = true
}

variable "nutanix_endpoint" {
  description = "Nutanix Prism Central/Element endpoint (IP or FQDN)"
  type        = string
}

variable "nutanix_port" {
  description = "Nutanix Prism Central/Element port"
  type        = number
  default     = 9440
}

variable "nutanix_insecure" {
  description = "Allow insecure connection (skip TLS verification)"
  type        = bool
  default     = true
}

variable "nutanix_wait_timeout" {
  description = "Timeout in minutes for resource operations"
  type        = number
  default     = 60
}

# ============================================================================
# Global Infrastructure Variables
# ============================================================================

variable "cluster_name" {
  description = "Name of the Nutanix cluster for VM deployment"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet for VM network connectivity"
  type        = string
}

# ============================================================================
# SAP Environment Configuration
# ============================================================================

variable "environment" {
  description = "Environment name (e.g., dev, test, prod)"
  type        = string
  validation {
    condition     = can(regex("^(dev|test|qa|prod|sandbox)$", var.environment))
    error_message = "Environment must be one of: dev, test, qa, prod, sandbox."
  }
}

variable "sap_landscape_name" {
  description = "Name of the SAP landscape for resource naming"
  type        = string
}

# ============================================================================
# Tagging and Organization
# ============================================================================

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Solution  = "SAP"
  }
}

# ============================================================================
# Ansible Integration
# ============================================================================

variable "generate_ansible_inventory" {
  description = "Generate Ansible inventory file from deployed VMs"
  type        = bool
  default     = true
}

variable "ansible_inventory_path" {
  description = "Path to write the Ansible inventory file"
  type        = string
  default     = "./ansible/inventory/hosts"
}

variable "ansible_connection_user" {
  description = "SSH user for Ansible connections"
  type        = string
  default     = "root"
}

