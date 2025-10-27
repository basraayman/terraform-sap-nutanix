# Terraform SAP on Nutanix

A comprehensive Terraform library for provisioning SAP workloads on Nutanix infrastructure with SAP note compliance.

## Important Notice

**DISCLAIMER**: This is a private initiative and is NOT officially supported by SAP SE or Nutanix, Inc. This project is provided as-is without warranty. For official support, please contact SAP and Nutanix through their standard support channels. Always validate configurations against official SAP and Nutanix documentation before production use.

**Please read the full [DISCLAIMER](./DISCLAIMER.md) before using this project.**

** Here be dragons!**:

This project is a work in progress and is not officially supported by SAP or Nutanix. I have created this project in my spare time to help myself and others learn about Terraform. Some of the code is auto generated, other parts are based on best practices, SAP notes, best practice guides on Nutanix, and my personal experience. Expect bugs and incomplete features, or even broken code. Please report any issues you find, or even better, submit a pull request. :-)

## Overview

This project provides reusable Terraform modules for deploying SAP systems on Nutanix AHV, incorporating best practices and SAP note requirements.

### Supported SAP Systems

- **SAP HANA** - Single node and scale-out configurations
- **SAP NetWeaver** - Application servers (ABAP, Java, Dual-stack)
- **SAP S/4HANA** - Distributed and converged deployments

## Features

- [x] Latest Nutanix Terraform Provider (1.9.x+)
- [x] SAP Note compliance built-in
- [x] Modular and extensible architecture
- [x] Support for multiple SAP scenarios
- [x] Storage layout per SAP best practices
- [x] Network and security configurations
- [x] Guest customization with cloud-init
- [x] Ansible inventory generation

## SAP Notes Implemented

The following SAP notes are incorporated into the module configurations:

| SAP Note | Description | Module |
|----------|-------------|--------|
| 1944799 | SAP HANA Guidelines for SLES Operating System Installation | sap-hana |
| 1900823 | SAP HANA Storage Connector API | sap-hana |
| 2686722 | SAP HANA virtualized on Nutanix AOS | sap-hana |
| 2205917 | SAP HANA: OS Settings for SLES 12 | all |
| 2684254 | SAP HANA: OS Settings for SLES 15 | all |
| 2772999 | Red Hat Enterprise Linux 8.x: Installation and Configuration | all |
| 3108316 | Red Hat Enterprise Linux 9.x: Installation and Configuration | all |

## Prerequisites

- Nutanix Prism Central or Prism Element
- Terraform >= 1.5.0
- Nutanix cluster with sufficient resources
- Pre-configured OS images (SLES, RHEL)
- Network subnets configured

## Quick Start

### 1. Configure Provider

```hcl
provider "nutanix" {
  username     = var.nutanix_username
  password     = var.nutanix_password
  endpoint     = var.nutanix_endpoint
  port         = 9440
  insecure     = true
  wait_timeout = 60
}
```

### 2. Deploy SAP HANA Single Node

```hcl
module "sap_hana" {
  source = "./modules/sap-hana"

  # VM Configuration
  vm_name              = "hanadb01"
  cluster_name         = "Production-Cluster"
  
  # SAP Sizing
  sap_system_size      = "S"  # XS, S, M, L, XL
  memory_gb            = 256
  num_vcpus            = 32
  
  # SAP HANA specific
  hana_sid             = "HDB"
  hana_instance_number = "00"
  
  # Storage
  os_image_name        = "SLES15-SP5-SAP"
  data_disk_count      = 4
  log_disk_count       = 3
  
  # Network
  subnet_name          = "SAP-Production"
  ip_address           = "10.10.10.100"  # Optional
  
  # Tags
  tags = {
    Environment = "Production"
    SAPSystem   = "HDB"
    Backup      = "Daily"
  }
}
```

### 3. Deploy SAP S/4HANA Distributed

```hcl
module "s4hana" {
  source = "./modules/sap-s4hana"

  # System Configuration
  sap_sid              = "S4D"
  landscape_type       = "distributed"  # converged or distributed
  
  # HANA Database
  hana_vm_config = {
    name       = "s4ddb"
    memory_gb  = 512
    num_vcpus  = 64
  }
  
  # Application Servers
  app_servers = [
    {
      name      = "s4dapp01"
      type      = "PAS"  # Primary Application Server
      memory_gb = 64
      num_vcpus = 16
    },
    {
      name      = "s4dapp02"
      type      = "AAS"  # Additional Application Server
      memory_gb = 64
      num_vcpus = 16
    }
  ]
}
```

## Project Structure

```
.
├── README.md                          # This file
├── main.tf                            # Root module
├── variables.tf                       # Root variables
├── outputs.tf                         # Root outputs
├── versions.tf                        # Provider versions
├── terraform.tfvars.example           # Example configuration
│
├── modules/                           # Reusable modules
│   ├── sap-hana/                      # SAP HANA module
│   ├── sap-netweaver/                 # SAP NetWeaver module
│   └── sap-s4hana/                    # SAP S/4HANA module
│
├── sap-notes/                         # SAP note configurations
│   ├── README.md                      # SAP notes documentation
│   ├── hana-storage-layout.tf        # Storage per SAP notes
│   ├── os-kernel-parameters.tf       # Kernel parameters
│   └── network-requirements.tf       # Network requirements
│
└── examples/                          # Example deployments
    ├── hana-single-node/              # Single node HANA
    ├── hana-scale-out/                # Scale-out HANA
    └── s4hana-distributed/            # Distributed S/4HANA
```

## Documentation

### Main Documentation

- **[Documentation Index](./docs/README.md)** - Complete documentation overview
- **[CHANGELOG](./CHANGELOG.md)** - Version history and changes
- **[QUICKSTART](./QUICKSTART.md)** - Quick start guide
- **[CONTRIBUTING](./CONTRIBUTING.md)** - Contribution guidelines

### Operations Guides

- **[LVM Storage Configuration](./docs/operations/LVM_STORAGE_CONFIGURATION.md)** - Complete LVM setup guide
- **[Post-Deployment CPU Configuration](./docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md)** - vNUMA and CPU pinning

### Module Documentation

#### SAP HANA Module

The SAP HANA module creates VMs optimized for SAP HANA databases with:
- Correct CPU and memory ratios per SAP sizing
- LVM-based storage layout following SAP Note 1900823
- NUMA optimization
- Network performance tuning

[Full documentation](./modules/sap-hana/README.md)

#### SAP NetWeaver Module

The NetWeaver module provisions application servers with:
- Flexible sizing for PAS, AAS, and Web Dispatcher
- Optimized for ABAP, Java, or Dual-stack
- Load balancing configuration support

[Full documentation](./modules/sap-netweaver/README.md)

#### SAP S/4HANA Module

The S/4HANA module orchestrates complete system deployments:
- HANA database + application tier
- Support for converged and distributed landscapes
- Central Services (ASCS/ERS) with high availability options

[Full documentation](./modules/sap-s4hana/README.md)

### SAP Notes Documentation

- **[SAP Notes Library](./sap-notes/README.md)** - Implemented SAP notes and compliance details

### Update Notes

- **[Updates Index](./docs/updates/README.md)** - Detailed update summaries
- [2024-10-27: LVM Storage Configuration](./docs/updates/2024-10-27-lvm-storage-configuration.md)
- [2024-10-26: SAP Notes Corrections](./docs/updates/2024-10-26-sap-notes-corrections.md)

## Adding New SAP Notes

To add compliance for new SAP notes:

1. Create a new file in `sap-notes/` directory
2. Define variables and locals for the note requirements
3. Include the file in relevant modules
4. Update documentation

Example:
```hcl
# sap-notes/sap-note-123456.tf
locals {
  sap_note_123456_kernel_params = {
    "vm.max_map_count" = "2147483647"
    # ... more parameters
  }
}
```

## Advanced Features

### Custom Disk Layouts

```hcl
custom_disk_layout = [
  { size_gb = 100, label = "os" },
  { size_gb = 500, label = "hana_data_1" },
  { size_gb = 500, label = "hana_data_2" },
  { size_gb = 250, label = "hana_log" },
  { size_gb = 200, label = "hana_shared" },
]
```

### Guest Customization with Cloud-Init

```hcl
cloud_init_config = {
  hostname = "hanadb01"
  users = [
    {
      name = "admin"
      ssh_authorized_keys = [file("~/.ssh/id_rsa.pub")]
      sudo = "ALL=(ALL) NOPASSWD:ALL"
    }
  ]
  packages = ["tuned-profiles-sap-hana"]
}
```

### Categories and Protection Policies

```hcl
categories = {
  "Environment" = "Production"
  "Application" = "SAP"
  "Compliance"  = "GDPR"
}

protection_policy_name = "SAP-Daily-Backup"
```

## Examples

See the [examples/](./examples/) directory for complete working examples:

- [Single Node HANA](./examples/hana-single-node/)
- [Scale-out HANA](./examples/hana-scale-out/)
- [Distributed S/4HANA](./examples/s4hana-distributed/)

## Contributing

To extend this library:

1. Add new modules in `modules/` directory
2. Follow the existing module structure
3. Include SAP note compliance where applicable
4. Update documentation
5. Add example configurations

Note: This is a community-driven project and not officially endorsed by SAP or Nutanix.

## Important: Post-Deployment Configuration

The Nutanix Terraform provider does not support advanced CPU configuration (vNUMA, CPU pinning, threads per core). These settings are **required for production SAP HANA systems** and must be configured manually after deployment using `acli` commands.

See [POST_DEPLOYMENT_CPU_CONFIG.md](./docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md) for complete instructions.

## References

- [SAP Sizing Guidelines](https://www.sap.com/about/benchmark/sizing.sizing-guidelines.html) - Official SAP sizing
- [Nutanix Terraform Provider Documentation](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs)
- [SAP on Nutanix Best Practices](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2065-SAP-HANA-on-Nutanix)
- [SAP Note 1944799](https://launchpad.support.sap.com/#/notes/1944799) - SLES OS Installation
- [SAP Note 1900823](https://launchpad.support.sap.com/#/notes/1900823) - Storage Connector API
- [SAP Note 2686722](https://launchpad.support.sap.com/#/notes/2686722) - HANA on Nutanix AOS
- [SAP Note 2205917](https://launchpad.support.sap.com/#/notes/2205917) - OS Settings for SLES 12
- [SAP Note 2684254](https://me.sap.com/notes/2684254) - OS Settings for SLES 15
- [SAP Note 2772999](https://launchpad.support.sap.com/#/notes/2772999) - RHEL 8.x Installation
- [SAP Note 3108316](https://launchpad.support.sap.com/#/notes/3108316) - RHEL 9.x Installation

## License

This project is provided as-is for use with SAP on Nutanix deployments.

This is an unofficial, community-driven project. It is not endorsed, supported, or maintained by SAP SE or Nutanix, Inc. Use at your own risk and always validate against official vendor documentation.

## Support

For issues and questions:
- Open an issue in the repository
- Consult Nutanix support for infrastructure issues
- Consult SAP support for SAP-specific issues

