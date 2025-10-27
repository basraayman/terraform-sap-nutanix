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
| 1944799 | SAP HANA Guidelines for Nutanix | CPU/Memory sizing, NUMA topology |
| 2205917 | SAP HANA Storage Requirements | Disk layout, sizes, separation |
| 2015553 | SAP on Linux Prerequisites | OS requirements, kernel parameters |
| 2684254 | SAP HANA on Nutanix Certification | Validated configurations |

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
| S    | 128         | 16    | 3          | 2         | Small Production, QA |
| M    | 256         | 32    | 4          | 3         | Medium Production |
| L    | 512         | 64    | 4          | 3         | Large Production |
| XL   | 1024        | 96    | 6          | 4         | Very Large Production |

## Storage Layout

The module automatically calculates storage sizes based on SAP Note 2205917:

- **OS Disk**: 100 GB (default, configurable)
- **/hana/data**: 1x RAM, striped across multiple disks
- **/hana/log**: 0.5x RAM, striped across multiple disks
- **/hana/shared**: 1x RAM
- **/hana/backup**: 2x RAM (optional, enabled by default)

### Example for 256 GB System:
- OS: 100 GB
- Data: 4 x 64 GB = 256 GB (striped for performance)
- Log: 3 x 43 GB = 129 GB (>0.5x RAM)
- Shared: 256 GB
- Backup: 512 GB
- **Total: 1,253 GB**

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
7. **Test in non-production** before production deployment

## References

- [SAP Note 1944799](https://launchpad.support.sap.com/#/notes/1944799) - SAP HANA on Nutanix
- [SAP Note 2205917](https://launchpad.support.sap.com/#/notes/2205917) - Storage Requirements
- [Nutanix SAP HANA Best Practices](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2065-SAP-HANA-on-Nutanix)

