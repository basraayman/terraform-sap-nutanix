# ============================================================================
# Terraform SAP on Nutanix - Provider Configuration
# ============================================================================

provider "nutanix" {
  username     = var.nutanix_username
  password     = var.nutanix_password
  endpoint     = var.nutanix_endpoint
  port         = var.nutanix_port
  insecure     = var.nutanix_insecure
  wait_timeout = var.nutanix_wait_timeout
}

