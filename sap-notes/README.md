# SAP Notes Configuration Library

This directory contains Terraform configuration files that implement specific SAP notes for systems running on Nutanix infrastructure.

**DISCLAIMER**: This is a community implementation of SAP notes and is NOT officially supported or endorsed by SAP SE or Nutanix, Inc. Always refer to official SAP notes and vendor documentation for authoritative information.

## Overview

SAP notes are official SAP recommendations and requirements. This library translates those requirements into reusable Terraform configurations that can be easily incorporated into SAP deployments.

## Structure

Each SAP note has its own `.tf` file containing:
- **Variables**: Configurable parameters per the note
- **Locals**: Calculated values and validations
- **Data structures**: Sizing tables, configuration maps, etc.

## Implemented SAP Notes

### Core SAP Notes

| SAP Note | Title | Module | Status |
|----------|-------|--------|--------|
| [1944799](https://launchpad.support.sap.com/#/notes/1944799) | SAP HANA Guidelines for Nutanix Systems | `sap-hana` | Implemented |
| [2205917](https://launchpad.support.sap.com/#/notes/2205917) | SAP HANA Storage Requirements | `sap-hana` | Implemented |
| [2015553](https://launchpad.support.sap.com/#/notes/2015553) | SAP on Linux: General Prerequisites | All | Implemented |
| [2684254](https://launchpad.support.sap.com/#/notes/2684254) | SAP HANA on Nutanix AHV - Certification | `sap-hana` | Implemented |
| [2235581](https://launchpad.support.sap.com/#/notes/2235581) | SAP HANA: Supported Operating Systems | All | Reference |

### OS-Specific Notes

| SAP Note | Title | OS | Status |
|----------|-------|-------|--------|
| [2382421](https://launchpad.support.sap.com/#/notes/2382421) | Optimizing Linux with tuned | RHEL/SLES | Implemented |
| [2777782](https://launchpad.support.sap.com/#/notes/2777782) | SAP HANA on RHEL 8.x | RHEL 8 | Implemented |
| [2205917](https://launchpad.support.sap.com/#/notes/2205917) | SAP HANA on SLES 15 | SLES 15 | Implemented |

### Networking Notes

| SAP Note | Title | Status |
|----------|-------|--------|
| [2081065](https://launchpad.support.sap.com/#/notes/2081065) | Jumbo Frames in HANA Environments | Reference |
| [2100040](https://launchpad.support.sap.com/#/notes/2100040) | FAQ: Network and Connectivity | Reference |

## Usage

### Method 1: Direct Include in Modules

SAP note configurations are already incorporated into the relevant modules:

```hcl
module "sap_hana" {
  source = "./modules/sap-hana"
  
  # SAP notes are automatically applied based on configuration
  sap_system_size = "M"  # Applies SAP Note 1944799 sizing
  # Storage layout automatically follows SAP Note 2205917
}
```

### Method 2: Use as Reference

For custom deployments, reference the note configurations:

```hcl
# Reference SAP note configurations
locals {
  # Import SAP Note 2205917 storage requirements
  sap_note_2205917 = {
    data_to_ram_ratio   = 1.0  # Minimum 1x RAM for data
    log_to_ram_ratio    = 0.5  # Minimum 0.5x RAM for log
    shared_to_ram_ratio = 1.0  # Typically 1x RAM for shared
    backup_to_ram_ratio = 2.0  # Typically 2x RAM for backup
  }
  
  # Calculate storage based on note
  memory_gb = 512
  data_volume_size  = local.memory_gb * local.sap_note_2205917.data_to_ram_ratio
  log_volume_size   = local.memory_gb * local.sap_note_2205917.log_to_ram_ratio
}
```

### Method 3: Extend with New Notes

To add a new SAP note:

1. Create file: `sap-notes/sap-note-XXXXXX.tf`
2. Define the requirements
3. Reference in modules

Example:
```hcl
# sap-notes/sap-note-123456.tf

locals {
  sap_note_123456_description = "Example SAP Note Implementation"
  
  sap_note_123456_kernel_parameters = {
    "vm.max_map_count"              = 2147483647
    "kernel.sem"                    = "1250 256000 100 1024"
    "net.ipv4.tcp_slow_start_after_idle" = 0
  }
  
  sap_note_123456_os_packages = [
    "package-name-1",
    "package-name-2"
  ]
}

# Use in cloud-init or configuration management
output "kernel_params_123456" {
  value = local.sap_note_123456_kernel_parameters
}
```

## SAP Note Details

### SAP Note 1944799 - SAP HANA Guidelines for Nutanix

**Key Requirements:**
- CPU: Intel Xeon processors (Cascade Lake or newer recommended)
- Memory: Minimum 64 GB, maximum 12 TB per VM
- NUMA: Proper NUMA alignment for systems > 256 GB
- Storage: See SAP Note 2205917

**Implementation:**
- T-shirt sizing presets (XS, S, M, L, XL)
- Automatic NUMA topology configuration
- Validated memory and CPU combinations

### SAP Note 2205917 - Storage Requirements

**Key Requirements:**
- Data: ≥ 1x RAM (striped across multiple disks)
- Log: ≥ 0.5x RAM (separate from data)
- Shared: ≥ 1x RAM (single volume)
- Backup: ≥ 2x RAM (recommended)

**Implementation:**
- Automatic size calculation based on memory
- Multiple disk striping for data and log
- Separate volumes per requirement

### SAP Note 2015553 - General Linux Prerequisites

**Key Requirements:**
- Supported OS versions (SLES 15 SP4+, RHEL 8.4+)
- Required packages and libraries
- Kernel parameters
- File system requirements

**Implementation:**
- Cloud-init package installation
- OS validation in modules
- Reference documentation

### SAP Note 2382421 - Linux Performance Optimization

**Key Requirements:**
- Use `tuned` profiles for SAP
- Specific kernel parameter tuning
- CPU frequency governor settings
- I/O scheduler configuration

**Implementation:**
- Cloud-init installs tuned profiles
- Can be extended via configuration management
- Reference values provided

## Adding Custom SAP Notes

### Step 1: Create Note File

```bash
cd sap-notes/
touch sap-note-XXXXXX.tf
```

### Step 2: Define Configuration

```hcl
# sap-notes/sap-note-XXXXXX.tf

variable "enable_sap_note_XXXXXX" {
  description = "Enable SAP Note XXXXXX requirements"
  type        = bool
  default     = true
}

locals {
  sap_note_XXXXXX_title = "SAP Note Title Here"
  
  sap_note_XXXXXX_config = {
    # Define requirements
    min_memory_gb = 128
    max_memory_gb = 2048
    
    # Define ratios or calculations
    some_ratio = 1.5
    
    # Define required settings
    required_settings = {
      setting1 = "value1"
      setting2 = "value2"
    }
  }
}

# Validation
resource "null_resource" "validate_sap_note_XXXXXX" {
  count = var.enable_sap_note_XXXXXX ? 1 : 0
  
  lifecycle {
    precondition {
      condition     = var.memory_gb >= local.sap_note_XXXXXX_config.min_memory_gb
      error_message = "SAP Note XXXXXX requires minimum ${local.sap_note_XXXXXX_config.min_memory_gb} GB memory"
    }
  }
}
```

### Step 3: Reference in Modules

```hcl
# In your module
module "sap_system" {
  source = "./modules/sap-hana"
  
  # Use note configuration
  memory_gb = local.sap_note_XXXXXX_config.min_memory_gb
  
  # Apply note requirements
  enable_sap_note_XXXXXX = true
}
```

### Step 4: Document

Update this README with:
- Note number and title
- Summary of requirements
- How it's implemented
- Usage examples

## Validation

Many SAP notes include validations in the modules:

```hcl
# Example validation from SAP Note 2205917
validation {
  condition     = var.data_disk_size_gb >= var.memory_gb
  error_message = "Per SAP Note 2205917, total data disk size must be >= RAM size"
}
```

## Testing SAP Note Compliance

To verify compliance:

1. **Review terraform plan output** - Check calculated sizes
2. **Check module outputs** - Verify configurations
3. **Use SAP tools** - Run SAP's Hardware Check Tool (HWCCT)
4. **Configuration audit** - Use Ansible or other tools post-deployment

## Contributing

When adding new SAP notes:

1. Use official SAP note numbers
2. Include note title and link
3. Document key requirements
4. Implement validations where possible
5. Provide usage examples
6. Update this README
7. Test with real deployments

## Resources

- [SAP Note Search](https://launchpad.support.sap.com/#/notes)
- [SAP HANA on Nutanix Best Practices](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2065-SAP-HANA-on-Nutanix)
- [SAP on Linux Documentation](https://www.sap.com/linux)
- [Nutanix SAP Certified Systems](https://www.nutanix.com/sap)

## License

These configurations implement publicly available SAP notes. Refer to SAP's licensing for SAP software and documentation.

