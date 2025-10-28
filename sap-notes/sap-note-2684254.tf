# ============================================================================
# SAP Note 2684254 - SAP HANA DB: Recommended OS Settings for SLES 15
# ============================================================================
#
# This file contains OS configuration recommendations from SAP Note 2684254
# for SLES 15 / SLES for SAP Applications 15.
#
# Link: https://me.sap.com/notes/2684254
#
# Note: For SLES 12, see SAP Note 2205917
# Note: For storage sizing, see SAP Note 1900823
#
# ============================================================================

locals {
  sap_note_2684254 = {
    note_number = "2684254"
    title       = "SAP HANA DB: Recommended OS Settings for SLES 15 / SLES for SAP Applications 15"
    version     = "Latest"
    applies_to  = "SLES 15"
    
    # ========================================================================
    # Required Packages for SLES 15
    # ========================================================================
    os_packages = {
      required = [
        "saptune",           # SAP system tuning tool
        "libgcc_s1",        # GCC runtime library
        "libstdc++6",       # Standard C++ library
        "libnuma1",         # NUMA policy library
        "libatomic1",       # Atomic operations library
      ]
      
      recommended = [
        "tuned",            # System tuning service
        "numactl",          # NUMA control tools
        "hwinfo",           # Hardware information
        "chrony",           # Time synchronization
        "lvm2",             # Logical Volume Manager
        "xfsprogs",         # XFS filesystem utilities
      ]
    }
    
    # ========================================================================
    # Kernel Parameters for SLES 15
    # ========================================================================
    kernel_parameters = {
      # Virtual memory settings
      "vm.max_map_count" = 2147483647
      "vm.swappiness" = 10
      
      # Shared memory
      "kernel.shmmni" = 32768
      "kernel.shmall" = 1152921504606846720
      "kernel.shmmax" = 1152921504606846720
      
      # Semaphores
      "kernel.sem" = "1250 256000 100 8192"
      
      # Network tuning
      "net.core.somaxconn" = 4096
      "net.ipv4.tcp_max_syn_backlog" = 8192
      "net.ipv4.ip_local_port_range" = "40000 65535"
      "net.ipv4.tcp_timestamps" = 1
      "net.ipv4.tcp_tw_reuse" = 1
      "net.ipv4.tcp_tw_recycle" = 0
      "net.ipv4.tcp_slow_start_after_idle" = 0
      "net.ipv4.tcp_syn_retries" = 8
      
      # File handles
      "fs.file-max" = 20000000
      "fs.aio-max-nr" = 18446744073709551615
    }
    
    # ========================================================================
    # SAP-Specific Kernel Parameters
    # ========================================================================
    sap_kernel_parameters = {
      # Transparent Huge Pages - MUST be disabled for HANA
      "transparent_hugepage" = "never"
      
      # NUMA balancing - disable for HANA
      "numa_balancing" = 0
      
      # CPU frequency governor
      "cpufreq_governor" = "performance"
    }
    
    # ========================================================================
    # Resource Limits for SLES 15
    # ========================================================================
    resource_limits = {
      sap_users = {
        nofile_soft  = 1048576
        nofile_hard  = 1048576
        nproc_soft   = "unlimited"
        nproc_hard   = "unlimited"
        memlock_soft = "unlimited"
        memlock_hard = "unlimited"
      }
    }
    
    # ========================================================================
    # saptune Configuration for SLES 15
    # ========================================================================
    saptune_config = {
      solution = "HANA"  # or NETWEAVER, S4HANA-APP+DB, etc.
      
      notes = [
        "1410736",  # Swap-Space Recommendation for Linux
        "1771258",  # Recommended OS settings for SLES 15
        "1980196",  # TCP/IP tuning
        "2205917",  # OS settings for SLES 12 (some apply to 15)
        "2382421",  # Optimizing Linux with tuned
        "2684254",  # This note - OS settings for SLES 15
      ]
      
      commands = {
        list_solutions = "saptune solution list"
        apply_solution = "saptune solution apply HANA"
        verify         = "saptune solution verify HANA"
        status         = "saptune status"
      }
    }
    
    # ========================================================================
    # File System Configuration
    # ========================================================================
    filesystem_config = {
      recommended_type = "xfs"
      
      mount_options = {
        data = [
          "relatime",
          "inode64",
          "logbufs=8",
          "logbsize=256k",
          "swalloc",
          "nobarrier",  # Only on resilient storage like Nutanix
        ]
        
        log = [
          "relatime",
          "inode64",
          "logbufs=8",
          "logbsize=256k",
          "nobarrier",
        ]
        
        shared = [
          "relatime",
          "inode64",
        ]
      }
      
      mkfs_options = {
        xfs = [
          "-b size=4096",
          "-d su=256k,sw=4",
          "-l size=128m",
          "-i size=512",
        ]
      }
    }
    
    # ========================================================================
    # Service Configuration
    # ========================================================================
    services = {
      enabled = [
        "chronyd",          # Time sync (preferred over ntpd)
        "rsyslog",          # System logging
        "saptune",          # SAP tuning service
      ]
      
      disabled = [
        "firewalld",        # Typically disabled (use network firewall)
        "kdump",            # Optional based on policy
        "numad",            # Conflicts with SAP HANA
      ]
    }
    
    # ========================================================================
    # Security Configuration
    # ========================================================================
    security = {
      selinux  = "disabled"  # Not applicable to SLES
      apparmor = "disabled"  # Must be disabled for SAP HANA
    }
    
    # ========================================================================
    # Cloud-Init Configuration for SLES 15
    # ========================================================================
    cloud_init_packages = [
      "saptune",
      "libgcc_s1",
      "libstdc++6",
      "libnuma1",
      "libatomic1",
      "chrony",
      "lvm2",
      "xfsprogs",
    ]
  }
}

# ============================================================================
# Validation
# ============================================================================

# ============================================================================
# Example Validation (Reference Only)
# ============================================================================
#
# To use validations in your modules:
#
# validation {
#   condition     = can(regex("SLES.*15", var.os_image_name))
#   error_message = "Per SAP Note 2684254, OS must be SLES 15"
# }

# ============================================================================
# Outputs
# ============================================================================

output "sap_note_2684254_info" {
  description = "SAP Note 2684254 implementation details"
  value = {
    note_number    = local.sap_note_2684254.note_number
    title          = local.sap_note_2684254.title
    applies_to     = local.sap_note_2684254.applies_to
    saptune_solution = local.sap_note_2684254.saptune_config.solution
    required_packages = length(local.sap_note_2684254.os_packages.required)
  }
}

