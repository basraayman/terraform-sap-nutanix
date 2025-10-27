# SAP HANA Module for Nutanix

This Terraform module deploys SAP HANA virtual machines on Nutanix infrastructure with built-in compliance for SAP notes and best practices.

**DISCLAIMER**: This is an unofficial module and is NOT supported by SAP SE or Nutanix, Inc. Always validate configurations against official documentation before production use.

## Features

- [x] Automated sizing based on SAP T-shirt sizes (XS, S, M, L, XL)
- [x] Storage layout per SAP Note 2205917
- [x] NUMA optimization for large memory configurations
- [x] Cloud-init support for guest OS customization
- [x] Backup integration with Nutanix protection policies
- [x] Support for dedicated HANA network interfaces
- [x] Ansible inventory generation

## SAP Notes Compliance

| SAP Note | Description | Implementation |
|----------|-------------|----------------|
| 1944799 | SAP HANA Guidelines for SLES Operating System Installation | OS configuration, packages |
| 1900823 | SAP HANA Storage Connector API | Storage sizing and configuration |
| 2686722 | SAP HANA virtualized on Nutanix AOS | Virtualization-specific settings |
| 2205917 | OS Settings for SLES 12 | Kernel parameters, packages |
| 2684254 | OS Settings for SLES 15 | Kernel parameters, saptune configuration |
| 2772999 | RHEL 8.x: Installation and Configuration | RHEL 8 specific settings |
| 3108316 | RHEL 9.x: Installation and Configuration | RHEL 9 specific settings |

## Usage

### Basic Example - Using Preset Sizing

```hcl
module "hana_database" {
  source = "./modules/sap-hana"

  # VM Configuration
  vm_name      = "hanadb01"
  cluster_uuid = data.nutanix_cluster.prod.id
  subnet_uuid  = data.nutanix_subnet.sap.id

  # SAP HANA Configuration
  hana_sid             = "HDB"
  hana_instance_number = "00"
  
  # Sizing - Use SAP T-shirt size
  sap_system_size      = "M"  # 256 GB RAM, 32 vCPUs
  
  # OS Image
  os_image_name        = "SLES15-SP5-SAP"
  
  # Optional: Override storage sizes
  # data_disk_size_gb    = 600
  # log_disk_size_gb     = 300
}
```

### Advanced Example - Custom Sizing

```hcl
module "hana_large" {
  source = "./modules/sap-hana"

  # VM Configuration
  vm_name      = "hanaprd01"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP HANA Configuration
  hana_sid             = "PRD"
  hana_instance_number = "00"
  hana_deployment_type = "single_node"
  
  # Custom Sizing
  sap_system_size      = "custom"
  memory_gb            = 768
  num_vcpus            = 96
  num_sockets          = 2  # For NUMA optimization
  
  # OS Configuration
  os_image_name        = "RHEL8-SAP"
  os_disk_size_gb      = 150
  
  # Storage Configuration
  data_disk_count      = 6
  data_disk_size_gb    = 500
  log_disk_count       = 4
  log_disk_size_gb     = 200
  shared_disk_size_gb  = 800
  backup_disk_size_gb  = 2000
  enable_backup_disk   = true
  
  # Network - Static IP
  ip_address           = "10.10.10.50"
  
  # Additional dedicated network for HANA replication
  additional_network_interfaces = [
    {
      subnet_uuid = data.nutanix_subnet.hana_replication.id
      ip_address  = "10.10.20.50"
    }
  ]
  
  # Cloud-init for initial configuration
  cloud_init_config = {
    ssh_authorized_keys = [
      file("~/.ssh/id_rsa.pub")
    ]
    additional_packages = [
      "tuned-profiles-sap-hana",
      "compat-sap-c++-11"
    ]
    timezone = "Europe/Berlin"
  }
  
  # Backup configuration
  protection_policy_name = "SAP-HANA-Daily"
  
  # Categories for organization
  categories = {
    Environment = "Production"
    CostCenter  = "SAP-HANA"
    Compliance  = "SOX"
  }
}
```

### Scale-Out Example

```hcl
# Master Node
module "hana_master" {
  source = "./modules/sap-hana"

  vm_name              = "hanaprd-master"
  cluster_uuid         = var.cluster_uuid
  subnet_uuid          = var.subnet_uuid
  
  hana_sid             = "PRD"
  hana_instance_number = "00"
  hana_deployment_type = "scale_out"
  
  sap_system_size      = "L"
  os_image_name        = "SLES15-SP5-SAP"
  ip_address           = "10.10.10.100"
}

# Worker Nodes
module "hana_worker" {
  count  = 3
  source = "./modules/sap-hana"

  vm_name              = "hanaprd-worker${count.index + 1}"
  cluster_uuid         = var.cluster_uuid
  subnet_uuid          = var.subnet_uuid
  
  hana_sid             = "PRD"
  hana_instance_number = "0${count.index + 1}"
  hana_deployment_type = "scale_out"
  
  sap_system_size      = "L"
  os_image_name        = "SLES15-SP5-SAP"
  ip_address           = "10.10.10.10${count.index + 1}"
}
```

## SAP System Sizing Presets

| Size | Memory (GB) | vCPUs | Data Disks | Log Disks | Use Case |
|------|-------------|-------|------------|-----------|----------|
| XS   | 64          | 8     | 2          | 2         | Development, Sandbox |
| S    | 128         | 16    | 2          | 2         | Small Production, QA |
| M    | 256         | 32    | 4          | 4         | Medium Production |
| L    | 512         | 64    | 4          | 4         | Large Production |
| XL   | 1024        | 96    | 4          | 4         | Very Large Production |

## Storage Layout

The module automatically calculates storage sizes based on SAP Note 1900823 and provisions disks that will be configured with **LVM (Logical Volume Manager)** post-deployment:

- **OS Disk**: 100 GB (default, configurable) - Separate disk, not part of data VGs
- **/hana/data**: 1.5x RAM, LVM striped across multiple disks (VG: hanadata)
- **/hana/log**: 0.5x RAM (systems ≤512GB) or min 512GB (systems >512GB), LVM striped (VG: hanalog)
- **/hana/shared**: MIN(1x RAM, 1TB) for single-node (VG: hanashared)
- **/hana/backup**: 2x RAM (optional, enabled by default)

### LVM Configuration

**Important**: Terraform provisions the disks, but LVM configuration must be done post-deployment using cloud-init or Ansible:

```bash
# Volume Groups (VG)
hanadata   - Data volume group
hanalog    - Log volume group  
hanashared - Shared volume group

# LVM Striping Parameters
Stripe Size:  1MB (-I1M)
Stripe Count: Matches disk count in VG (-i <count>)
Capacity:     100% of VG (-l 100%FREE)

# XFS Mount Options
inode64,largeio,swalloc
```

See [LVM_STORAGE_CONFIGURATION.md](../../docs/operations/LVM_STORAGE_CONFIGURATION.md) for complete LVM setup instructions.

### Example for 256 GB System (9 data disks):
```
Total Disks: 10 (1 OS + 9 data)

OS:          1 disk  × 100 GB = 100 GB (separate, not in VG)
/hana/data:  4 disks × 96 GB  = 384 GB total (VG: hanadata, 4-way LVM stripe)
/hana/log:   4 disks × 32 GB  = 128 GB total (VG: hanalog, 4-way LVM stripe)
/hana/shared:1 disk  × 256 GB = 256 GB total (VG: hanashared, no stripe)
/hana/backup:1 disk  × 512 GB = 512 GB total (optional)

Total Storage: 1,380 GB
```

### Example for 1024 GB System (12 data disks):
```
Total Disks: 13 (1 OS + 12 data)

OS:          1 disk  × 100 GB  = 100 GB (separate, not in VG)
/hana/data:  4 disks × 384 GB  = 1,536 GB total (VG: hanadata, 4-way LVM stripe)
/hana/log:   4 disks × 128 GB  = 512 GB total (VG: hanalog, 4-way LVM stripe)
/hana/shared:4 disks × 256 GB  = 1,024 GB total (VG: hanashared, 4-way LVM stripe)
/hana/backup:1 disk  × 2048 GB = 2,048 GB total (optional)

Total Storage: 5,220 GB
```

**Note**: No RAID configuration is used. Nutanix provides data protection (RF2/RF3) at the storage layer. LVM striping provides performance optimization.

## CPU and NUMA Configuration

The module automatically optimizes CPU topology for NUMA:

- Systems < 32 vCPUs: 1 socket
- Systems >= 32 vCPUs: 2 sockets
- Custom configurations can override with `num_sockets`

This ensures optimal memory locality per SAP recommendations.

## Network Configuration

### Primary Network
- Configured via `subnet_uuid` and optional `ip_address`
- Used for SAP client connections and administration

### Additional Networks
Use `additional_network_interfaces` for:
- HANA system replication traffic
- Backup network
- Storage network (if using separate storage network)
- Inter-node communication (scale-out)

## Cloud-Init Integration

The module supports cloud-init for initial VM configuration:

```hcl
cloud_init_config = {
  ssh_authorized_keys = [
    "ssh-rsa AAAAB3Nza..."
  ]
  additional_packages = [
    "tuned-profiles-sap-hana",
    "compat-sap-c++-11",
    "resource-agents-sap-hana"
  ]
  timezone = "UTC"
}
```

## Outputs

The module provides comprehensive outputs for integration:

- `vm_uuid`: VM identifier
- `ip_address`: Primary IP address
- `hana_configuration`: SAP HANA settings
- `vm_resources`: CPU and memory allocation
- `storage_configuration`: Complete storage layout
- `ansible_host_vars`: Variables for Ansible automation

## Integration with Ansible

Use the output for Ansible inventory:

```hcl
output "ansible_inventory" {
  value = <<-EOT
    [hana_database]
    ${module.hana_database.vm_name} ansible_host=${module.hana_database.ip_address}
    
    [hana_database:vars]
    sap_hana_sid=${module.hana_database.hana_configuration.sid}
    sap_hana_instance=${module.hana_database.hana_configuration.instance_number}
  EOT
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| nutanix | ~> 1.9.0 |

## Providers

| Name | Version |
|------|---------|
| nutanix | ~> 1.9.0 |

## Variables

See [variables.tf](./variables.tf) for complete variable documentation.

## Outputs

See [outputs.tf](./outputs.tf) for complete output documentation.

## Best Practices

1. **Use T-shirt sizing** for standard deployments (XS, S, M, L, XL)
2. **Use custom sizing** only when specific requirements exist
3. **Enable backup disk** for production systems
4. **Use static IPs** for production databases
5. **Configure protection policies** for automated backups
6. **Use categories** for organization and automation
7. **Configure LVM storage** post-deployment (always required) - See [LVM Storage Guide](../../docs/operations/LVM_STORAGE_CONFIGURATION.md)
8. **Configure vNUMA and CPU pinning** post-deployment (required for production) - See [CPU Config Guide](../../docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md)
9. **Disable Hyper-Threading** for SAP HANA (num_threads_per_core=1)
10. **Use XFS filesystem** with mount options: inode64,largeio,swalloc
11. **Separate OS disk** from data disks - Never include OS disk in HANA volume groups
12. **Test in non-production** before production deployment

## Post-Deployment Configuration

**IMPORTANT**: After Terraform provisions the VM and disks, you must complete two critical configuration steps:

### 1. LVM Storage Configuration (Required)

Configure LVM volume groups and logical volumes for SAP HANA storage:

```bash
# Example for 9-disk configuration (4 data + 4 log + 1 shared)
# Exclude OS disk (typically /dev/sda)

# Create physical volumes
pvcreate /dev/sdb /dev/sdc /dev/sdd /dev/sde    # Data disks
pvcreate /dev/sdf /dev/sdg /dev/sdh /dev/sdi    # Log disks
pvcreate /dev/sdj                                # Shared disk

# Create volume groups
vgcreate hanadata /dev/sdb /dev/sdc /dev/sdd /dev/sde
vgcreate hanalog /dev/sdf /dev/sdg /dev/sdh /dev/sdi
vgcreate hanashared /dev/sdj

# Create logical volumes with LVM striping (1MB stripe size)
lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanadata
lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanalog
lvcreate -l 100%FREE -r none -n vol hanashared

# Format with XFS
mkfs.xfs /dev/mapper/hanadata-vol
mkfs.xfs /dev/mapper/hanalog-vol
mkfs.xfs /dev/mapper/hanashared-vol

# Create mount points
mkdir -p /hana/{data,log,shared}

# Add to /etc/fstab
echo "/dev/mapper/hanadata-vol /hana/data xfs inode64,largeio,swalloc 1 2" >> /etc/fstab
echo "/dev/mapper/hanalog-vol /hana/log xfs inode64,largeio,swalloc 1 2" >> /etc/fstab
echo "/dev/mapper/hanashared-vol /hana/shared xfs inode64,largeio,swalloc 1 2" >> /etc/fstab

# Mount all
mount -a
```

See [LVM_STORAGE_CONFIGURATION.md](../../docs/operations/LVM_STORAGE_CONFIGURATION.md) for detailed instructions, automation examples, and troubleshooting.

### 2. CPU Configuration (Required for Production)

Configure vNUMA, CPU pinning, and disable Hyper-Threading:

```bash
acli vm.update <vm_name> \
  num_vcpus=2 \
  num_vnuma_nodes=2 \
  num_cores_per_vcpu=32 \
  vcpu_hard_pin=True \
  num_threads_per_core=1
```

See [POST_DEPLOYMENT_CPU_CONFIG.md](../../docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md) for detailed CPU configuration instructions.

## References

- [SAP Sizing Guidelines](https://www.sap.com/about/benchmark/sizing.sizing-guidelines.html) - Official SAP Sizing
- [SAP Note 1944799](https://launchpad.support.sap.com/#/notes/1944799) - SLES OS Installation
- [SAP Note 1900823](https://launchpad.support.sap.com/#/notes/1900823) - Storage Connector API
- [SAP Note 2686722](https://launchpad.support.sap.com/#/notes/2686722) - HANA on Nutanix AOS
- [SAP Note 2205917](https://launchpad.support.sap.com/#/notes/2205917) - OS Settings for SLES 12
- [SAP Note 2684254](https://me.sap.com/notes/2684254) - OS Settings for SLES 15
- [SAP Note 2772999](https://launchpad.support.sap.com/#/notes/2772999) - RHEL 8.x Installation
- [SAP Note 3108316](https://launchpad.support.sap.com/#/notes/3108316) - RHEL 9.x Installation
- [Nutanix SAP HANA Best Practices](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2065-SAP-HANA-on-Nutanix)

