# SAP NetWeaver Module for Nutanix

This Terraform module deploys SAP NetWeaver application servers on Nutanix infrastructure.

**DISCLAIMER**: This is an unofficial module and is NOT supported by SAP SE or Nutanix, Inc. Always validate configurations against official documentation before production use.

## Supported Instance Types

- **PAS** (Primary Application Server) - First application server with dialog instances
- **AAS** (Additional Application Server) - Additional dialog instances
- **ASCS** (ABAP Central Services) - Message server and enqueue server
- **ERS** (Enqueue Replication Server) - Enqueue replication for HA
- **WDP** (Web Dispatcher) - HTTP(S) load balancer

## Features

- [x] Support for all NetWeaver instance types
- [x] ABAP, Java, and Dual-stack configurations
- [x] Flexible sizing per instance type
- [x] Optimized storage layout
- [x] Cloud-init integration
- [x] Ansible inventory generation

## Usage

### Primary Application Server (PAS)

```hcl
module "sap_pas" {
  source = "./modules/sap-netweaver"

  # VM Configuration
  vm_name      = "sapapp01"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = "NPL"
  instance_number  = "00"
  instance_type    = "PAS"
  stack_type       = "ABAP"

  # Sizing
  memory_gb = 64
  num_vcpus = 16

  # Storage
  os_image_name        = "SLES15-SP5-SAP"
  os_disk_size_gb      = 100
  usrsap_disk_size_gb  = 150

  # Network
  ip_address = "10.10.10.20"
}
```

### ABAP Central Services (ASCS)

```hcl
module "sap_ascs" {
  source = "./modules/sap-netweaver"

  # VM Configuration
  vm_name      = "sapascs01"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = "NPL"
  instance_number  = "01"
  instance_type    = "ASCS"
  stack_type       = "ABAP"

  # Sizing
  memory_gb = 32
  num_vcpus = 8

  # Storage
  os_image_name        = "SLES15-SP5-SAP"
  sapmnt_disk_size_gb  = 200  # Shared filesystem

  # Network
  ip_address = "10.10.10.21"
}
```

### Additional Application Server (AAS)

```hcl
module "sap_aas" {
  count  = 2
  source = "./modules/sap-netweaver"

  # VM Configuration
  vm_name      = "sapapp0${count.index + 2}"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = "NPL"
  instance_number  = "0${count.index + 2}"
  instance_type    = "AAS"
  stack_type       = "ABAP"

  # Sizing
  memory_gb = 64
  num_vcpus = 16

  # Storage
  os_image_name        = "SLES15-SP5-SAP"
  usrsap_disk_size_gb  = 100

  # Network
  ip_address = "10.10.10.${count.index + 22}"
}
```

### Web Dispatcher

```hcl
module "sap_webdispatcher" {
  source = "./modules/sap-netweaver"

  # VM Configuration
  vm_name      = "sapwdp01"
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid          = "NPL"
  instance_number  = "80"
  instance_type    = "WDP"
  stack_type       = "ABAP"

  # Sizing (smaller for WDP)
  memory_gb = 16
  num_vcpus = 8

  # Storage
  os_image_name        = "SLES15-SP5-SAP"

  # Network
  ip_address = "10.10.10.30"
}
```

## Instance Type Sizing Guidelines

| Instance Type | Min Memory | Recommended Memory | Min vCPUs | Recommended vCPUs | Description |
|---------------|------------|-------------------|-----------|-------------------|-------------|
| PAS           | 32 GB      | 64 GB            | 8         | 16                | Primary app server |
| AAS           | 32 GB      | 64 GB            | 8         | 16                | Additional app server |
| ASCS          | 16 GB      | 32 GB            | 4         | 8                 | Central services |
| ERS           | 16 GB      | 32 GB            | 4         | 8                 | Enqueue replication |
| WDP           | 8 GB       | 16 GB            | 4         | 8                 | Web dispatcher |

## Storage Layout

### Standard Layout
- **OS Disk**: 100 GB (root filesystem)
- **/usr/sap**: 100-150 GB (SAP binaries and instance files)
- **/sapmnt**: 200 GB+ (shared filesystem, typically on ASCS)

### High Availability Layout
For HA scenarios, consider:
- Shared storage for `/sapmnt`, `/usr/sap/trans`
- Dedicated disks for cluster software
- Additional storage for backup/archive

## Stack Types

### ABAP Stack
Traditional ABAP applications (ERP, CRM, SCM)

```hcl
stack_type = "ABAP"
```

### Java Stack
Java-based applications (PI/PO, Portal)

```hcl
stack_type = "JAVA"
```

### Dual Stack
Both ABAP and Java (being phased out)

```hcl
stack_type = "DUAL"
memory_gb = 96  # Requires more memory
```

## Complete NetWeaver System Example

```hcl
# ASCS Instance
module "nw_ascs" {
  source = "./modules/sap-netweaver"
  
  vm_name         = "sapnpl-ascs"
  cluster_uuid    = var.cluster_uuid
  subnet_uuid     = var.subnet_uuid
  
  sap_sid         = "NPL"
  instance_number = "01"
  instance_type   = "ASCS"
  
  memory_gb       = 32
  num_vcpus       = 8
  
  os_image_name        = "SLES15-SP5-SAP"
  sapmnt_disk_size_gb  = 200
  
  ip_address      = "10.10.10.21"
}

# ERS Instance (for HA)
module "nw_ers" {
  source = "./modules/sap-netweaver"
  
  vm_name         = "sapnpl-ers"
  cluster_uuid    = var.cluster_uuid
  subnet_uuid     = var.subnet_uuid
  
  sap_sid         = "NPL"
  instance_number = "02"
  instance_type   = "ERS"
  
  memory_gb       = 32
  num_vcpus       = 8
  
  os_image_name   = "SLES15-SP5-SAP"
  ip_address      = "10.10.10.22"
}

# PAS Instance
module "nw_pas" {
  source = "./modules/sap-netweaver"
  
  vm_name         = "sapnpl-pas"
  cluster_uuid    = var.cluster_uuid
  subnet_uuid     = var.subnet_uuid
  
  sap_sid         = "NPL"
  instance_number = "00"
  instance_type   = "PAS"
  
  memory_gb       = 64
  num_vcpus       = 16
  
  os_image_name        = "SLES15-SP5-SAP"
  usrsap_disk_size_gb  = 150
  
  ip_address      = "10.10.10.20"
  
  depends_on = [module.nw_ascs]
}

# AAS Instances
module "nw_aas" {
  count  = 2
  source = "./modules/sap-netweaver"
  
  vm_name         = "sapnpl-aas0${count.index + 1}"
  cluster_uuid    = var.cluster_uuid
  subnet_uuid     = var.subnet_uuid
  
  sap_sid         = "NPL"
  instance_number = "0${count.index + 3}"
  instance_type   = "AAS"
  
  memory_gb       = 64
  num_vcpus       = 16
  
  os_image_name        = "SLES15-SP5-SAP"
  usrsap_disk_size_gb  = 100
  
  ip_address      = "10.10.10.${23 + count.index}"
  
  depends_on = [module.nw_pas]
}
```

## Integration with SAP HANA

```hcl
# HANA Database
module "hana_db" {
  source = "./modules/sap-hana"
  
  vm_name         = "sapnpl-db"
  hana_sid        = "NPL"
  sap_system_size = "M"
  # ... other config
}

# NetWeaver PAS (connects to HANA)
module "nw_pas" {
  source = "./modules/sap-netweaver"
  
  vm_name         = "sapnpl-pas"
  sap_sid         = "NPL"
  instance_type   = "PAS"
  # ... other config
  
  depends_on = [module.hana_db]
}
```

## Cloud-Init Configuration

```hcl
cloud_init_config = {
  ssh_authorized_keys = [
    file("~/.ssh/id_rsa.pub")
  ]
  additional_packages = [
    "sapconf",
    "tuned-profiles-sap"
  ]
  timezone = "Europe/Berlin"
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| nutanix | ~> 1.9.0 |

## Variables

See [variables.tf](./variables.tf) for complete variable documentation.

## Outputs

See [outputs.tf](./outputs.tf) for complete output documentation.

## References

- [SAP Note 1928533](https://launchpad.support.sap.com/#/notes/1928533) - SAP Applications on Linux
- [SAP Note 2015553](https://launchpad.support.sap.com/#/notes/2015553) - SAP on Linux Prerequisites
- [SAP Installation Guides](https://help.sap.com/docs/SAP_NETWEAVER)

