# ============================================================================
# SAP Note 2015553 - SAP Applications on Linux: General Information
# ============================================================================
#
# This file contains OS-level requirements from SAP Note 2015553
# which defines general prerequisites for SAP on Linux systems.
#
# Link: https://launchpad.support.sap.com/#/notes/2015553
#
# ============================================================================

locals {
  sap_note_2015553 = {
    note_number = "2015553"
    title       = "SAP Applications on Linux: General Information"
    version     = "Latest"
    
    # ========================================================================
    # OS Requirements
    # ========================================================================
    os_requirements = {
      # Required packages (common across distributions)
      required_packages = [
        "chrony",                    # Time synchronization
        "rsyslog",                   # System logging
        "net-tools",                 # Network utilities
        "bind-utils",                # DNS utilities
        "lvm2",                      # Logical volume management
        "xfsprogs",                  # XFS utilities
        "tuned",                     # System tuning
      ]
      
      # SLES-specific packages
      sles_packages = [
        "sapconf",                   # SAP configuration tool
        "saptune",                   # SAP system tuning
        "libatomic1",               # Atomic operations
        "libnuma1",                 # NUMA policy library
      ]
      
      # RHEL-specific packages
      rhel_packages = [
        "tuned-profiles-sap",        # SAP tuning profiles
        "tuned-profiles-sap-hana",   # HANA-specific profiles
        "compat-sap-c++-11",        # SAP C++ compatibility
        "libnuma",                   # NUMA policy library
      ]
    }
    
    # ========================================================================
    # Kernel Parameters
    # ========================================================================
    kernel_parameters = {
      # Virtual memory settings
      "vm.max_map_count" = 2147483647
      "vm.swappiness" = 10
      
      # Shared memory settings
      "kernel.shmmni" = 32768
      "kernel.shmall" = 1152921504606846720
      "kernel.shmmax" = 1152921504606846720
      
      # Semaphores (sem)
      "kernel.sem" = "1250 256000 100 8192"
      
      # Message queues
      "kernel.msgmni" = 1024
      
      # Network settings
      "net.ipv4.tcp_keepalive_time" = 300
      "net.ipv4.tcp_keepalive_intvl" = 75
      "net.ipv4.tcp_keepalive_probes" = 9
      "net.ipv4.tcp_tw_reuse" = 1
      "net.ipv4.tcp_fin_timeout" = 30
      "net.ipv4.ip_local_port_range" = "40000 65535"
      "net.core.somaxconn" = 4096
      "net.ipv4.tcp_max_syn_backlog" = 8192
      
      # File handles
      "fs.file-max" = 20000000
      "fs.aio-max-nr" = 18446744073709551615
    }
    
    # ========================================================================
    # HANA-Specific Kernel Parameters
    # ========================================================================
    hana_kernel_parameters = {
      # THP (Transparent Huge Pages) - must be disabled
      "transparent_hugepage" = "never"
      
      # NUMA balancing - disable for HANA
      "numa_balancing" = 0
      
      # CPU frequency governor
      "cpufreq_governor" = "performance"
      
      # Additional network tuning
      "net.core.rmem_max" = 16777216
      "net.core.wmem_max" = 16777216
      "net.ipv4.tcp_rmem" = "4096 87380 16777216"
      "net.ipv4.tcp_wmem" = "4096 65536 16777216"
      "net.core.netdev_max_backlog" = 300000
      "net.ipv4.tcp_slow_start_after_idle" = 0
      "net.ipv4.tcp_no_metrics_save" = 1
    }
    
    # ========================================================================
    # Resource Limits (/etc/security/limits.conf)
    # ========================================================================
    resource_limits = {
      # SAP system user limits
      sap_user = {
        nofile_soft = 1048576
        nofile_hard = 1048576
        nproc_soft  = unlimited
        nproc_hard  = unlimited
        core_soft   = unlimited
        core_hard   = unlimited
        memlock_soft = unlimited
        memlock_hard = unlimited
      }
      
      # Root user limits
      root = {
        nofile_soft = 1048576
        nofile_hard = 1048576
      }
    }
    
    # ========================================================================
    # Required Services
    # ========================================================================
    services = {
      enabled = [
        "chronyd",                   # Time synchronization (chrony)
        "rsyslog",                   # System logging
        "tuned",                     # System tuning daemon
      ]
      
      disabled = [
        "firewalld",                 # Typically disabled (use network FW)
        "abrtd",                     # Automatic bug reporting
        "kdump",                     # Kernel dump (optional based on policy)
      ]
    }
    
    # ========================================================================
    # SELinux / AppArmor
    # ========================================================================
    security = {
      selinux_mode = "permissive"    # Or disabled for SAP
      apparmor_mode = "disabled"     # Should be disabled for SAP
    }
    
    # ========================================================================
    # Tuned Profiles
    # ========================================================================
    tuned_profiles = {
      sles = {
        sap_hana = "sap-hana"
        sap_netweaver = "sap-netweaver"
        sap_ase = "sap-ase"
        sap_bobj = "sap-bobj"
      }
      
      rhel = {
        sap_hana = "sap-hana"
        sap_netweaver = "sap-netweaver"
      }
    }
    
    # ========================================================================
    # Time Synchronization
    # ========================================================================
    time_sync = {
      service = "chronyd"            # Preferred over ntpd
      max_offset_seconds = 300       # Maximum time offset
      
      # Recommended chrony configuration
      chrony_config = {
        makestep = "1.0 3"          # Step if offset > 1s in first 3 updates
        rtcsync = true               # Sync RTC to system time
      }
    }
    
    # ========================================================================
    # Hostname Requirements
    # ========================================================================
    hostname = {
      max_length = 13                # Maximum hostname length for SAP
      valid_chars = "[a-z0-9-]"     # Valid characters
      must_be_resolvable = true      # Must resolve via DNS or /etc/hosts
    }
    
    # ========================================================================
    # File System Requirements
    # ========================================================================
    filesystem = {
      supported_types = ["xfs", "ext4"]
      recommended = "xfs"
      
      required_mount_points = [
        "/",
        "/usr/sap",
      ]
      
      hana_mount_points = [
        "/hana/data",
        "/hana/log",
        "/hana/shared",
        "/hana/backup",
      ]
    }
  }
}

# ============================================================================
# Cloud-Init Template for SAP Note 2015553
# ============================================================================

locals {
  sap_note_2015553_cloud_init = {
    # Kernel parameters for sysctl
    sysctl_config = merge(
      local.sap_note_2015553.kernel_parameters,
      var.enable_hana_tuning ? local.sap_note_2015553.hana_kernel_parameters : {}
    )
    
    # Package list based on OS
    packages = concat(
      local.sap_note_2015553.os_requirements.required_packages,
      var.os_type == "sles" ? local.sap_note_2015553.os_requirements.sles_packages : [],
      var.os_type == "rhel" ? local.sap_note_2015553.os_requirements.rhel_packages : []
    )
  }
}

# ============================================================================
# Validation
# ============================================================================

locals {
  validate_2015553 = {
    # Validate hostname length
    hostname_valid = length(var.vm_name) <= local.sap_note_2015553.hostname.max_length
    
    # Validate hostname characters
    hostname_chars_valid = can(regex("^${local.sap_note_2015553.hostname.valid_chars}+$", var.vm_name))
  }
}

# ============================================================================
# Outputs
# ============================================================================

output "sap_note_2015553_info" {
  description = "SAP Note 2015553 implementation details"
  value = {
    note_number        = local.sap_note_2015553.note_number
    title              = local.sap_note_2015553.title
    kernel_params      = length(local.sap_note_2015553.kernel_parameters)
    required_packages  = length(local.sap_note_2015553_cloud_init.packages)
    tuned_profiles     = local.sap_note_2015553.tuned_profiles
  }
}

