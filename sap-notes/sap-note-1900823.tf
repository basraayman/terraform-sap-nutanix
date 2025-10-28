# ============================================================================
# SAP Note 1900823 - SAP HANA Storage Requirements
# ============================================================================
#
# This file contains storage sizing calculations from SAP Note 1900823
# which defines the official storage requirements for SAP HANA.
#
# Link: https://launchpad.support.sap.com/#/notes/1900823
#
# ============================================================================

locals {
  sap_note_1900823 = {
    note_number = "1900823"
    title       = "SAP HANA Storage Requirements"
    version     = "Latest"
    
    # ========================================================================
    # Storage Sizing Formulas
    # ========================================================================
    storage_formulas = {
      # /hana/data sizing
      data = {
        size_ratio_to_ram = 1.5  # Sizedata = 1.5 x RAM
        description       = "Data volume must be 1.5 times the configured memory"
      }
      
      # /hana/log sizing
      log = {
        small_systems = {
          threshold_gb      = 512
          size_ratio_to_ram = 0.5  # Sizeredolog = 1/2 x RAM
          description       = "For systems ≤ 512GB: Log = 0.5 x RAM"
        }
        large_systems = {
          threshold_gb      = 512
          minimum_size_gb   = 512  # Sizeredolog(min) = 512GB
          description       = "For systems > 512GB: Log minimum = 512GB"
        }
      }
      
      # /hana/shared sizing (single-node)
      shared_single_node = {
        size_ratio_to_ram = 1.0
        maximum_size_gb   = 1024  # 1 TB
        formula           = "MIN(1 x RAM; 1 TB)"
        description       = "Shared volume is minimum of RAM or 1TB"
      }
      
      # /hana/shared sizing (scale-out)
      shared_scale_out = {
        size_ratio_to_ram     = 1.0
        workers_per_increment = 4
        formula               = "1 x RAM_of_worker per 4 worker nodes"
        description           = "For scale-out: 1x RAM per 4 worker nodes"
      }
    }
    
    # ========================================================================
    # Storage Calculation Functions
    # ========================================================================
    
    # Example calculations for reference
    examples = {
      system_64gb = {
        ram_gb    = 64
        data_gb   = 96   # 64 * 1.5
        log_gb    = 32   # 64 * 0.5
        shared_gb = 64   # MIN(64, 1024)
      }
      
      system_256gb = {
        ram_gb    = 256
        data_gb   = 384  # 256 * 1.5
        log_gb    = 128  # 256 * 0.5
        shared_gb = 256  # MIN(256, 1024)
      }
      
      system_512gb = {
        ram_gb    = 512
        data_gb   = 768  # 512 * 1.5
        log_gb    = 256  # 512 * 0.5
        shared_gb = 512  # MIN(512, 1024)
      }
      
      system_1024gb = {
        ram_gb    = 1024
        data_gb   = 1536 # 1024 * 1.5
        log_gb    = 512  # min 512GB for systems > 512GB
        shared_gb = 1024 # MIN(1024, 1024) = 1TB
      }
      
      system_2048gb = {
        ram_gb    = 2048
        data_gb   = 3072 # 2048 * 1.5
        log_gb    = 512  # min 512GB (not 1024)
        shared_gb = 1024 # MIN(2048, 1024) = 1TB (capped)
      }
    }
    
    # ========================================================================
    # Disk Layout Recommendations (LVM-based for Nutanix)
    # ========================================================================
    disk_layout = {
      # Data volume - LVM striping
      data_volume = {
        volume_manager      = "LVM"
        striping_recommended = true
        min_disks           = 2
        stripe_size_kb      = 1024       # 1MB stripe size for LVM
        vg_name             = "hanadata"
        lv_name             = "vol"
        lvm_stripe_option   = "-i"       # Number of stripes
        lvm_stripe_size     = "-I1M"     # 1MB stripe size
        
        # Disk count by system size
        disk_count_by_size = {
          "XS"  = 2  # Up to 128GB
          "S"   = 2  # Up to 256GB
          "M"   = 4  # Up to 512GB
          "L"   = 4  # Up to 1TB
          "XL"  = 4  # Above 1TB
        }
        
        # LVM creation command example
        lvcreate_command = "lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanadata"
      }
      
      # Log volume - LVM configuration
      log_volume = {
        volume_manager      = "LVM"
        striping_recommended = true
        min_disks           = 2
        stripe_size_kb      = 1024       # 1MB stripe size for LVM
        vg_name             = "hanalog"
        lv_name             = "vol"
        lvm_stripe_option   = "-i"
        lvm_stripe_size     = "-I1M"
        
        # Disk count by system size
        disk_count_by_size = {
          "XS"  = 2  # Up to 128GB
          "S"   = 2  # Up to 256GB
          "M"   = 4  # Up to 512GB
          "L"   = 4  # Up to 1TB
          "XL"  = 4  # Above 1TB
        }
        
        # LVM creation command example
        lvcreate_command = "lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanalog"
      }
      
      # Shared volume - LVM configuration
      shared_volume = {
        volume_manager      = "LVM"
        striping_recommended = false  # Single disk for XS/S/M/L, 4 disks for XL
        vg_name             = "hanashared"
        lv_name             = "vol"
        disk_count          = 1       # 1 for small/medium, 4 for XL
        
        # LVM creation command example (no striping for small systems)
        lvcreate_command = "lvcreate -l 100%FREE -r none -n vol hanashared"
      }
    }
    
    # ========================================================================
    # File System Types
    # ========================================================================
    supported_filesystems = {
      recommended = "xfs"
      alternatives = []  # SAP officially supports only XFS for HANA on SLES/RHEL
      
      # XFS mount options for SAP HANA on Nutanix
      # Based on SAP recommendations and Nutanix best practices
      xfs_mount_options = {
        data   = "inode64,largeio,swalloc"
        log    = "inode64,largeio,swalloc"
        shared = "inode64,largeio,swalloc"
      }
      
      # fstab entries with dump and pass options
      fstab_entries = {
        data   = "/dev/mapper/hanadata-vol /hana/data xfs inode64,largeio,swalloc 1 2"
        log    = "/dev/mapper/hanalog-vol /hana/log xfs inode64,largeio,swalloc 1 2"
        shared = "/dev/mapper/hanashared-vol /hana/shared xfs inode64,largeio,swalloc 1 2"
      }
      
      # Mount option explanations
      mount_option_details = {
        inode64  = "Allows inode allocation across entire filesystem (required for >1TB)"
        largeio  = "Optimizes for large I/O operations (SAP HANA large sequential I/O)"
        swalloc  = "Stripe width allocation - aligns I/O with LVM stripe geometry"
      }
    }
    
    # ========================================================================
    # Storage Performance Requirements
    # ========================================================================
    performance_requirements = {
      data_volume = {
        iops_min          = "High"
        throughput_min_mb = 400
        latency_max_ms    = 5
      }
      
      log_volume = {
        iops_min          = "Very High"
        throughput_min_mb = 250
        latency_max_ms    = 2
        write_pattern     = "Sequential"
      }
      
      shared_volume = {
        iops_min          = "Medium"
        throughput_min_mb = 100
        latency_max_ms    = 10
      }
    }
    
    # ========================================================================
    # Additional Notes for Nutanix Implementation
    # ========================================================================
    important_notes = [
      "Use LVM (not RAID) - Nutanix provides data protection at storage layer",
      "Data and log volumes must be on separate LVM volume groups",
      "Use XFS file system with mount options: inode64,largeio,swalloc",
      "LVM striping: 1MB stripe size (-I1M) for optimal performance",
      "Use 100% of disk capacity: -l 100%FREE in lvcreate",
      "Stripe count should match number of disks in volume group: -i <count>",
      "Ensure storage is sized for future data growth",
      "For productive systems, add backup space (typically 2x data+log)",
      "Consider compression ratio in data sizing",
      "For scale-out, each worker needs same sizing",
      "Always use separate OS disk - exclude from data VGs",
    ]
    
    # ========================================================================
    # Nutanix-Specific LVM Configuration
    # ========================================================================
    nutanix_lvm_config = {
      # Total disk configurations supported
      supported_disk_counts = [3, 9, 12]  # Excluding OS disk
      
      # 3-disk layout (minimal)
      layout_3_disk = {
        total_data_disks = 3
        hanadata_disks   = 1
        hanalog_disks    = 1
        hanashared_disks = 1
        striping_enabled = false
        use_case         = "Development, sandbox"
      }
      
      # 9-disk layout (standard)
      layout_9_disk = {
        total_data_disks = 9
        hanadata_disks   = 4
        hanalog_disks    = 4
        hanashared_disks = 1
        striping_enabled = true
        stripe_count     = 4
        use_case         = "Small to medium production"
      }
      
      # 12-disk layout (large)
      layout_12_disk = {
        total_data_disks = 12
        hanadata_disks   = 4
        hanalog_disks    = 4
        hanashared_disks = 4
        striping_enabled = true
        stripe_count     = 4
        use_case         = "Large production systems"
      }
      
      # LVM creation steps
      setup_steps = [
        "1. Create physical volumes: pvcreate /dev/sd[x]",
        "2. Create volume groups: vgcreate <vgname> /dev/sd[x] /dev/sd[y] ...",
        "3. Create logical volumes: lvcreate -i <count> -I1M -l 100%FREE -r none -n vol <vgname>",
        "4. Format with XFS: mkfs.xfs /dev/mapper/<vgname>-vol",
        "5. Create mount points: mkdir -p /hana/{data,log,shared}",
        "6. Add to fstab: /dev/mapper/<vgname>-vol /hana/<mount> xfs inode64,largeio,swalloc 1 2",
        "7. Mount all: mount -a",
      ]
    }
  }
}

# ============================================================================
# Example Usage (Reference Only)
# ============================================================================
#
# To use these storage formulas in your modules, reference them like this:
#
# locals {
#   # Calculate data volume size
#   data_gb = var.memory_gb * local.sap_note_1900823.storage_formulas.data.size_ratio_to_ram
#   
#   # Calculate log volume size with threshold logic
#   log_gb = var.memory_gb <= 512 ? (
#     var.memory_gb * 0.5
#   ) : (
#     512  # Minimum 512GB for large systems
#   )
#   
#   # Calculate shared volume size (single-node)
#   shared_gb = min(
#     var.memory_gb * 1.0,  # 1x RAM
#     1024                  # Maximum 1TB
#   )
# }
#
# # Example validation
# validation {
#   condition     = (var.data_disk_size_gb * var.data_disk_count) >= (var.memory_gb * 1.5)
#   error_message = "Per SAP Note 1900823, total data disk size must be >= 1.5x RAM"
# }

# ============================================================================
# Outputs
# ============================================================================

output "sap_note_1900823_info" {
  description = "SAP Note 1900823 storage sizing information"
  value = {
    note_number    = local.sap_note_1900823.note_number
    title          = local.sap_note_1900823.title
    data_formula   = "1.5 x RAM"
    log_formula    = "0.5 x RAM (≤512GB) or min 512GB (>512GB)"
    shared_formula = "MIN(1 x RAM, 1TB) for single-node"
  }
}

