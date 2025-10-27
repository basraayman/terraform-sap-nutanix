# ============================================================================
# SAP Note 2205917 - SAP HANA DB: Recommended OS Settings for SLES 12
# ============================================================================
#
# This file contains OS configuration recommendations from SAP Note 2205917
# for SLES 12 / SLES for SAP Applications 12.
#
# Link: https://launchpad.support.sap.com/#/notes/2205917
#
# Note: For SLES 15, see SAP Note 2684254
# Note: For storage sizing, see SAP Note 1900823
#
# ============================================================================

locals {
  sap_note_2205917 = {
    note_number = "2205917"
    title       = "SAP HANA DB: Recommended OS Settings for SLES 12 / SLES for SAP Applications 12"
    version     = "Latest"
    applies_to  = "SLES 12"
    
    # ========================================================================
    # OS Configuration for SLES 12
    # ========================================================================
    os_packages = {
      required = [
        "saptune",
        "sapconf",
        
        # Disk configuration
        min_disks             = 1
        recommended_disks     = 4      # For performance via striping
        max_disks             = 8
        
        # File system
        filesystem            = "xfs"
        mount_point           = "/hana/data"
        mount_options         = "defaults,nofail,relatime,inode64"
        
        # Performance
        stripe_size_kb        = 256
        requires_striping     = true
      }
      
      # /hana/log - Transaction logs
      log = {
        min_size_ratio_to_ram = 0.5    # Minimum 0.5x RAM
        rec_size_ratio_to_ram = 0.5    # Recommended 0.5x RAM
        max_size_ratio_to_ram = 0.75   # Can be larger for heavy write workloads
        
        # Disk configuration
        min_disks             = 1
        recommended_disks     = 3      # For performance and redundancy
        max_disks             = 4
        
        # File system
        filesystem            = "xfs"
        mount_point           = "/hana/log"
        mount_options         = "defaults,nofail,relatime,inode64"
        
        # Performance
        stripe_size_kb        = 64
        requires_striping     = true
        separate_from_data    = true   # Must be separate from data
      }
      
      # /hana/shared - Shared files and binaries
      shared = {
        min_size_ratio_to_ram = 1.0    # Minimum 1x RAM
        rec_size_ratio_to_ram = 1.0    # Recommended 1x RAM
        max_size_ratio_to_ram = 1.0    # Typically doesn't need more
        
        # Disk configuration
        min_disks             = 1
        recommended_disks     = 1      # Single disk sufficient
        max_disks             = 1
        
        # File system
        filesystem            = "xfs"
        mount_point           = "/hana/shared"
        mount_options         = "defaults,nofail,relatime"
        
        # Performance
        requires_striping     = false
      }
      
      # /hana/backup - Backup storage (optional but recommended)
      backup = {
        min_size_ratio_to_ram = 2.0    # Minimum 2x RAM
        rec_size_ratio_to_ram = 2.5    # Recommended 2.5x RAM (for multiple backups)
        max_size_ratio_to_ram = 4.0    # For long retention
        
        # Disk configuration
        min_disks             = 1
        recommended_disks     = 1      # Single large disk
        max_disks             = 1
        
        # File system
        filesystem            = "xfs"
        mount_point           = "/hana/backup"
        mount_options         = "defaults,nofail,relatime"
        
        # Performance
        requires_striping     = false
        can_use_external      = true   # Can use external backup solution
      }
      
      # Root filesystem
      root = {
        min_size_gb           = 50
        rec_size_gb           = 100
        max_size_gb           = 200
        
        filesystem            = "xfs"
        mount_point           = "/"
        mount_options         = "defaults"
      }
    }
    
    # ========================================================================
    # Storage Layout by System Size
    # ========================================================================
    layouts = {
      # Small systems (< 256 GB RAM)
      small = {
        memory_range_gb = "64-256"
        data_disks      = 3
        log_disks       = 2
        shared_disks    = 1
        backup_disks    = 1
        total_disks     = 7
      }
      
      # Medium systems (256-512 GB RAM)
      medium = {
        memory_range_gb = "257-512"
        data_disks      = 4
        log_disks       = 3
        shared_disks    = 1
        backup_disks    = 1
        total_disks     = 9
      }
      
      # Large systems (> 512 GB RAM)
      large = {
        memory_range_gb = "513+"
        data_disks      = 6
        log_disks       = 4
        shared_disks    = 1
        backup_disks    = 1
        total_disks     = 12
      }
    }
    
    # ========================================================================
    # I/O Characteristics
    # ========================================================================
    io_requirements = {
      data_volume = {
        iops_per_gb         = 100      # Minimum IOPS per GB
        throughput_mbps_min = 400
        throughput_mbps_rec = 1000
        latency_ms_max      = 5
      }
      
      log_volume = {
        iops_per_gb         = 200      # Higher IOPS for logs
        throughput_mbps_min = 250
        throughput_mbps_rec = 500
        latency_ms_max      = 2        # Stricter latency requirement
        sequential_writes   = true      # Optimize for sequential
      }
      
      shared_volume = {
        iops_per_gb         = 50
        throughput_mbps_min = 100
        throughput_mbps_rec = 250
        latency_ms_max      = 10
      }
      
      backup_volume = {
        iops_per_gb         = 50
        throughput_mbps_min = 250
        throughput_mbps_rec = 1000     # Higher for faster backups
        latency_ms_max      = 20        # Less critical
      }
    }
    
    # ========================================================================
    # File System Parameters
    # ========================================================================
    filesystem_config = {
      xfs = {
        mkfs_options = [
          "-b size=4096",              # Block size
          "-d sw=4,su=256k",          # Stripe width and unit
          "-l size=128m",             # Log size
          "-i size=512",              # Inode size
        ]
        
        mount_options_data = [
          "relatime",
          "inode64",
          "logbufs=8",
          "logbsize=256k",
          "nobarrier",                # On resilient storage
          "swalloc",
        ]
        
        mount_options_log = [
          "relatime",
          "inode64",
          "logbufs=8",
          "logbsize=256k",
          "nobarrier",
        ]
      }
    }
    
    # ========================================================================
    # Disk Organization Best Practices (Nutanix LVM-based)
    # ========================================================================
    best_practices = {
      volume_management = {
        technology            = "LVM"  # Use LVM, not RAID
        stripe_size_kb        = 1024   # 1MB stripe size for LVM
        use_full_capacity     = true   # Always use 100% (-l 100%FREE)
        separate_os_disk      = true   # OS disk separate from data VGs
      }
      
      data_striping = {
        enabled               = true
        stripe_size_kb        = 1024   # 1MB for LVM
        min_disks_for_stripe  = 2
        volume_group          = "hanadata"
        logical_volume        = "vol"
        lvcreate_options      = "-i <count> -I1M -l 100%FREE -r none"
      }
      
      log_striping = {
        enabled               = true
        stripe_size_kb        = 1024   # 1MB for LVM
        min_disks_for_stripe  = 2
        volume_group          = "hanalog"
        logical_volume        = "vol"
        lvcreate_options      = "-i <count> -I1M -l 100%FREE -r none"
      }
      
      separation = {
        data_log_separate     = true   # Data and log must be on separate VGs
        backup_can_share      = false  # Backup should be separate VG
        shared_can_share      = false  # Shared should be separate VG
        os_must_be_separate   = true   # OS disk must be separate
      }
      
      thin_provisioning = {
        data_volume           = false  # Not recommended for data
        log_volume            = false  # Not recommended for log
        shared_volume         = false  # Not recommended for shared
        backup_volume         = true   # OK for backup
        note                  = "Nutanix thin provisioning at storage layer is acceptable"
      }
      
      filesystem = {
        type                  = "xfs"
        mount_options         = "inode64,largeio,swalloc"
        format_command        = "mkfs.xfs"
        fstab_dump_option     = 1
        fstab_pass_option     = 2
      }
    }
  }
}

# ============================================================================
# Storage Calculation Functions
# ============================================================================

locals {
  # Calculate storage sizes based on memory
  calculate_storage = {
    # Input memory in GB
    memory_gb = var.memory_gb
    
    # Calculate data volume size
    data_volume_gb = ceil(local.calculate_storage.memory_gb * 
                         local.sap_note_2205917.volumes.data.rec_size_ratio_to_ram)
    
    # Calculate log volume size
    log_volume_gb = ceil(local.calculate_storage.memory_gb * 
                        local.sap_note_2205917.volumes.log.rec_size_ratio_to_ram)
    
    # Calculate shared volume size
    shared_volume_gb = ceil(local.calculate_storage.memory_gb * 
                           local.sap_note_2205917.volumes.shared.rec_size_ratio_to_ram)
    
    # Calculate backup volume size
    backup_volume_gb = ceil(local.calculate_storage.memory_gb * 
                           local.sap_note_2205917.volumes.backup.rec_size_ratio_to_ram)
    
    # Total storage required
    total_storage_gb = local.calculate_storage.data_volume_gb + 
                       local.calculate_storage.log_volume_gb + 
                       local.calculate_storage.shared_volume_gb + 
                       local.calculate_storage.backup_volume_gb +
                       local.sap_note_2205917.volumes.root.rec_size_gb
  }
  
  # Determine layout based on memory size
  storage_layout = (
    var.memory_gb <= 256 ? local.sap_note_2205917.layouts.small :
    var.memory_gb <= 512 ? local.sap_note_2205917.layouts.medium :
    local.sap_note_2205917.layouts.large
  )
}

# ============================================================================
# Validation
# ============================================================================

locals {
  validate_storage = {
    # Ensure data volume meets minimum
    data_meets_minimum = var.data_disk_size_gb * var.data_disk_count >= 
                        (var.memory_gb * local.sap_note_2205917.volumes.data.min_size_ratio_to_ram)
    
    # Ensure log volume meets minimum
    log_meets_minimum = var.log_disk_size_gb * var.log_disk_count >= 
                       (var.memory_gb * local.sap_note_2205917.volumes.log.min_size_ratio_to_ram)
    
    # Ensure proper disk count for striping
    data_disk_count_ok = var.data_disk_count >= local.sap_note_2205917.volumes.data.recommended_disks
    log_disk_count_ok  = var.log_disk_count >= local.sap_note_2205917.volumes.log.recommended_disks
  }
}

# ============================================================================
# Outputs for Reference
# ============================================================================

output "sap_note_2205917_info" {
  description = "SAP Note 2205917 storage recommendations"
  value = {
    note_number           = local.sap_note_2205917.note_number
    title                 = local.sap_note_2205917.title
    calculated_sizes      = local.calculate_storage
    recommended_layout    = local.storage_layout
  }
}

