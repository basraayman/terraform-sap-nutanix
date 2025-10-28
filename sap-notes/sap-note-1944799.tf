# ============================================================================
# SAP Note 1944799 - SAP HANA Guidelines for Nutanix Systems
# ============================================================================
#
# This file contains configuration values derived from SAP Note 1944799
# which defines the requirements and guidelines for running SAP HANA on
# Nutanix infrastructure.
#
# Link: https://launchpad.support.sap.com/#/notes/1944799
#
# ============================================================================

locals {
  sap_note_1944799 = {
    note_number = "1944799"
    title       = "SAP HANA Guidelines for Nutanix Systems"
    version     = "Latest"
    
    # ========================================================================
    # CPU Requirements
    # ========================================================================
    cpu = {
      # Supported processor families
      supported_processors = [
        "Intel Xeon Cascade Lake",
        "Intel Xeon Ice Lake",
        "Intel Xeon Sapphire Rapids",
        "AMD EPYC 7002 Series",
        "AMD EPYC 7003 Series",
        "AMD EPYC 9004 Series"
      ]
      
      # Minimum vCPU requirements by workload
      min_vcpus_oltp = 4
      min_vcpus_olap = 8
      
      # Maximum vCPUs per VM
      max_vcpus = 256
      
      # Recommended vCPU to memory ratio (GB per vCPU)
      vcpu_to_memory_ratio_min = 4    # 1 vCPU per 4 GB RAM (minimum)
      vcpu_to_memory_ratio_rec = 8    # 1 vCPU per 8 GB RAM (recommended)
      vcpu_to_memory_ratio_max = 16   # 1 vCPU per 16 GB RAM (maximum)
    }
    
    # ========================================================================
    # Memory Requirements
    # ========================================================================
    memory = {
      # Memory limits (in GB)
      min_memory_gb = 64
      max_memory_gb = 12288  # 12 TB
      
      # Recommended memory sizes for different workloads
      workload_sizes = {
        dev_sandbox     = 64
        qa_small        = 128
        prod_small      = 256
        prod_medium     = 512
        prod_large      = 1024
        prod_very_large = 2048
      }
      
      # NUMA configuration thresholds
      numa_threshold_gb = 256  # Use 2 sockets for > 256 GB
      
      # Memory reservation (should be 100% for production)
      reservation_percent = 100
    }
    
    # ========================================================================
    # T-Shirt Sizing Presets
    # ========================================================================
    tshirt_sizes = {
      XS = {
        memory_gb   = 64
        vcpus       = 8
        sockets     = 1
        cores       = 8
        use_case    = "Development, Sandbox, PoC"
        max_users   = 25
        data_disks  = 2
        log_disks   = 2
      }
      S = {
        memory_gb   = 128
        vcpus       = 16
        sockets     = 1
        cores       = 16
        use_case    = "Small Production, QA"
        max_users   = 50
        data_disks  = 3
        log_disks   = 2
      }
      M = {
        memory_gb   = 256
        vcpus       = 32
        sockets     = 2
        cores       = 16
        use_case    = "Medium Production"
        max_users   = 150
        data_disks  = 4
        log_disks   = 3
      }
      L = {
        memory_gb   = 512
        vcpus       = 64
        sockets     = 2
        cores       = 32
        use_case    = "Large Production"
        max_users   = 500
        data_disks  = 4
        log_disks   = 3
      }
      XL = {
        memory_gb   = 1024
        vcpus       = 96
        sockets     = 2
        cores       = 48
        use_case    = "Very Large Production, Scale-out"
        max_users   = 1000
        data_disks  = 6
        log_disks   = 4
      }
    }
    
    # ========================================================================
    # NUMA Configuration
    # ========================================================================
    numa = {
      # Enable NUMA optimization for systems above threshold
      enable_above_gb = 256
      
      # Preferred socket configuration by memory size
      socket_config = {
        "64-256"     = { sockets = 1, cores_per_socket = "auto" }
        "257-512"    = { sockets = 2, cores_per_socket = "auto" }
        "513-1024"   = { sockets = 2, cores_per_socket = "auto" }
        "1025-2048"  = { sockets = 2, cores_per_socket = "auto" }
        "2049-12288" = { sockets = 2, cores_per_socket = "auto" }
      }
    }
    
    # ========================================================================
    # Supported Operating Systems
    # ========================================================================
    supported_os = {
      sles = {
        "15_SP4" = { supported = true, recommended = false }
        "15_SP5" = { supported = true, recommended = true }
        "15_SP6" = { supported = true, recommended = true }
      }
      rhel = {
        "8_4" = { supported = true, recommended = false }
        "8_6" = { supported = true, recommended = true }
        "8_8" = { supported = true, recommended = true }
        "9_0" = { supported = true, recommended = true }
      }
    }
    
    # ========================================================================
    # Network Requirements
    # ========================================================================
    network = {
      min_bandwidth_gbps = 10
      recommended_bandwidth_gbps = 25
      
      # Network interface requirements
      min_nics = 1
      recommended_nics_prod = 2  # Separate client and backup networks
      
      # MTU settings
      jumbo_frames_recommended = true
      mtu_size = 9000
    }
    
    # ========================================================================
    # Certification Status
    # ========================================================================
    certification = {
      certified = true
      certification_type = "TDI"  # Tailored Data Center Integration
      certified_platforms = [
        "Nutanix AHV",
      ]
    }
  }
}

# ============================================================================
# Example Validation (Reference Only)
# ============================================================================
#
# To use validations in your modules, add them like this:
#
# validation {
#   condition     = var.num_vcpus >= 8 && var.num_vcpus <= 384
#   error_message = "Per SAP Note 1944799, vCPU count must be between 8 and 384"
# }
#
# validation {
#   condition     = var.memory_gb >= 64 && var.memory_gb <= 6144
#   error_message = "Per SAP Note 1944799, memory must be between 64GB and 6144GB"
# }

# ============================================================================
# Outputs for Reference
# ============================================================================

output "sap_note_1944799_info" {
  description = "SAP Note 1944799 implementation details"
  value = {
    note_number        = local.sap_note_1944799.note_number
    title              = local.sap_note_1944799.title
    certified          = local.sap_note_1944799.certification.certified
    tshirt_sizes       = keys(local.sap_note_1944799.tshirt_sizes)
    supported_os       = keys(local.sap_note_1944799.supported_os)
  }
}

