# SAP S/4HANA Module for Nutanix

This Terraform module orchestrates complete SAP S/4HANA system deployments on Nutanix infrastructure, including database, central services, and application servers.

**DISCLAIMER**: This is an unofficial module and is NOT supported by SAP SE or Nutanix, Inc. Always validate configurations against official documentation before production use.

## Features

- [x] Complete S/4HANA landscape deployment
- [x] Converged and distributed architectures
- [x] High availability support (ASCS/ERS)
- [x] Automatic Ansible inventory generation
- [x] Flexible application server scaling
- [x] Optional Web Dispatcher
- [x] Integrated with SAP HANA and NetWeaver modules

## Architecture Types

### Distributed (Recommended for Production)
Separate VMs for each component:
- HANA Database
- ASCS (Central Services)
- ERS (Enqueue Replication - optional for HA)
- PAS (Primary Application Server)
- AAS (Additional Application Servers - optional)
- Web Dispatcher (optional)

### Converged (Development/Test)
Database and application on same VM (not recommended for production)

## Usage

### Basic Distributed S/4HANA System

```hcl
module "s4hana_prod" {
  source = "./modules/sap-s4hana"

  # Infrastructure
  cluster_uuid = data.nutanix_cluster.prod.id
  subnet_uuid  = data.nutanix_subnet.sap.id

  # SAP Configuration
  sap_sid        = "S4P"
  landscape_type = "distributed"
  stack_type     = "ABAP"

  # HANA Database
  hana_vm_config = {
    memory_gb   = 512
    num_vcpus   = 64
    image_name  = "SLES15-SP5-SAP"
    ip_address  = "10.10.10.10"
  }

  # Primary Application Server
  pas_vm_config = {
    memory_gb   = 64
    num_vcpus   = 16
    ip_address  = "10.10.10.20"
  }

  # Central Services (ASCS)
  deploy_ascs = true
  ascs_vm_config = {
    memory_gb   = 32
    num_vcpus   = 8
    ip_address  = "10.10.10.21"
  }

  # Tags
  tags = {
    Environment = "Production"
    CostCenter  = "SAP"
  }
}
```

### Production with High Availability

```hcl
module "s4hana_ha" {
  source = "./modules/sap-s4hana"

  # Infrastructure
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  # SAP Configuration
  sap_sid        = "PRD"
  landscape_type = "distributed"

  # HANA Database (Large)
  hana_vm_config = {
    memory_gb      = 1024
    num_vcpus      = 96
    image_name     = "RHEL8-SAP"
    system_size    = "XL"
    ip_address     = "10.10.10.10"
  }

  # ASCS
  deploy_ascs = true
  ascs_instance_number = "01"
  ascs_vm_config = {
    memory_gb   = 32
    num_vcpus   = 8
    ip_address  = "10.10.10.21"
  }

  # ERS (for HA)
  deploy_ers = true
  ers_instance_number = "02"
  ers_vm_config = {
    memory_gb   = 32
    num_vcpus   = 8
    ip_address  = "10.10.10.22"
  }

  # PAS
  pas_vm_config = {
    memory_gb   = 128
    num_vcpus   = 32
    ip_address  = "10.10.10.20"
  }

  # Multiple Application Servers
  additional_app_servers = [
    {
      memory_gb   = 128
      num_vcpus   = 32
      ip_address  = "10.10.10.23"
    },
    {
      memory_gb   = 128
      num_vcpus   = 32
      ip_address  = "10.10.10.24"
    },
    {
      memory_gb   = 128
      num_vcpus   = 32
      ip_address  = "10.10.10.25"
    }
  ]

  # Web Dispatcher
  deploy_web_dispatcher = true
  web_dispatcher_vm_config = {
    memory_gb   = 16
    num_vcpus   = 8
    ip_address  = "10.10.10.30"
  }

  # Cloud-init
  cloud_init_config = {
    ssh_authorized_keys = [file("~/.ssh/id_rsa.pub")]
    additional_packages = ["sapconf", "tuned-profiles-sap-hana"]
    timezone            = "UTC"
  }

  # Ansible
  generate_ansible_inventory = true
  ansible_inventory_path     = "./ansible/inventory/${var.sap_sid}"
  ansible_user               = "root"

  tags = {
    Environment = "Production"
    HA          = "true"
  }
}
```

### Development System (Converged)

```hcl
module "s4hana_dev" {
  source = "./modules/sap-s4hana"

  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid

  sap_sid        = "DEV"
  landscape_type = "converged"  # DB + App on same VM

  # Single VM configuration
  hana_vm_config = {
    memory_gb   = 256
    num_vcpus   = 32
    image_name  = "SLES15-SP5-SAP"
  }

  pas_vm_config = {
    memory_gb   = 64
    num_vcpus   = 16
  }

  # Skip ASCS for simplicity in dev
  deploy_ascs = false

  tags = {
    Environment = "Development"
  }
}
```

### Complete Example with All Options

```hcl
module "s4hana_complete" {
  source = "./modules/sap-s4hana"

  # Infrastructure
  cluster_uuid = data.nutanix_cluster.prod.id
  subnet_uuid  = data.nutanix_subnet.sap_prod.id

  # SAP System
  sap_sid        = "S4P"
  landscape_type = "distributed"
  stack_type     = "ABAP"

  # HANA Database - Use T-shirt sizing
  hana_instance_number = "00"
  hana_vm_config = {
    memory_gb         = 768
    num_vcpus         = 96
    image_name        = "SLES15-SP5-SAP"
    system_size       = "L"
    data_disk_count   = 6
    log_disk_count    = 4
    enable_backup_disk = true
    ip_address        = "10.10.10.10"
  }

  # ASCS
  deploy_ascs          = true
  ascs_instance_number = "01"
  ascs_vm_config = {
    memory_gb          = 32
    num_vcpus          = 8
    image_name         = "SLES15-SP5-SAP"
    sapmnt_disk_size_gb = 500
    ip_address         = "10.10.10.11"
  }

  # ERS
  deploy_ers          = true
  ers_instance_number = "02"
  ers_vm_config = {
    memory_gb   = 32
    num_vcpus   = 8
    ip_address  = "10.10.10.12"
  }

  # PAS
  pas_instance_number = "00"
  pas_vm_config = {
    memory_gb          = 128
    num_vcpus          = 32
    usrsap_disk_size_gb = 200
    ip_address         = "10.10.10.20"
  }

  # Scale-out with 3 AAS
  additional_app_servers = [
    {
      memory_gb   = 128
      num_vcpus   = 32
      ip_address  = "10.10.10.21"
    },
    {
      memory_gb   = 128
      num_vcpus   = 32
      ip_address  = "10.10.10.22"
    },
    {
      memory_gb   = 64
      num_vcpus   = 16
      ip_address  = "10.10.10.23"
    }
  ]

  # Web Dispatcher for load balancing
  deploy_web_dispatcher        = true
  web_dispatcher_instance_number = "80"
  web_dispatcher_vm_config = {
    memory_gb   = 32
    num_vcpus   = 16
    ip_address  = "10.10.10.30"
  }

  # Guest customization
  cloud_init_config = {
    ssh_authorized_keys = [
      file("~/.ssh/sap_deployment.pub")
    ]
    additional_packages = [
      "sapconf",
      "tuned-profiles-sap-hana",
      "resource-agents-sap-hana",
      "sap-suse-cluster-connector"
    ]
    timezone = "Europe/Berlin"
  }

  # Ansible automation
  generate_ansible_inventory = true
  ansible_inventory_path     = "./ansible/inventory/s4p-prod"
  ansible_user               = "ansible"

  # Organization
  tags = {
    Environment  = "Production"
    Application  = "S/4HANA"
    CostCenter   = "SAP-01"
    Owner        = "SAP-Basis-Team"
    Backup       = "Daily"
    Compliance   = "SOX"
    Project      = "S4HANA-Greenfield"
  }
}
```

## Outputs

The module provides comprehensive outputs:

```hcl
# Access landscape information
output "s4hana_landscape" {
  value = module.s4hana_prod.landscape_info
}

# Get all VM IPs
output "all_systems" {
  value = module.s4hana_prod.all_vms
}

# Connection info
output "sap_connection" {
  value = module.s4hana_prod.connection_info
}
```

## Instance Number Planning

| Component | Default | Typical Range | Notes |
|-----------|---------|---------------|-------|
| HANA      | 00      | 00-09        | Database instance |
| ASCS      | 01      | 01-19        | Central services |
| ERS       | 02      | 01-19        | Enqueue replication |
| PAS       | 00      | 00, 20-79    | Primary app server |
| AAS       | 01+     | 01-79        | Additional app servers |
| WDP       | 80      | 80-99        | Web dispatcher |

## Sizing Recommendations

### Small Production (< 100 users)
- HANA: 256 GB RAM, 32 vCPUs
- ASCS: 32 GB RAM, 8 vCPUs
- PAS: 64 GB RAM, 16 vCPUs
- AAS: 0-1 additional servers

### Medium Production (100-500 users)
- HANA: 512 GB RAM, 64 vCPUs
- ASCS: 32 GB RAM, 8 vCPUs
- ERS: 32 GB RAM, 8 vCPUs (for HA)
- PAS: 128 GB RAM, 32 vCPUs
- AAS: 2-3 additional servers

### Large Production (> 500 users)
- HANA: 1024 GB RAM, 96 vCPUs
- ASCS: 32 GB RAM, 8 vCPUs
- ERS: 32 GB RAM, 8 vCPUs
- PAS: 128 GB RAM, 32 vCPUs
- AAS: 4+ additional servers
- WDP: 2 instances (load balanced)

## Integration with Ansible

The module automatically generates an Ansible inventory file:

```ini
[hana_database]
s4p-db ansible_host=10.10.10.10

[sap_ascs]
s4p-ascs ansible_host=10.10.10.11

[sap_pas]
s4p-pas ansible_host=10.10.10.20

[sap_aas]
s4p-aas01 ansible_host=10.10.10.21
s4p-aas02 ansible_host=10.10.10.22

[all:vars]
ansible_user=root
sap_sid=S4P
```

Use with Ansible:
```bash
ansible-playbook -i $(terraform output -raw ansible_inventory_path) site.yml
```

## Best Practices

1. **Use distributed architecture** for production systems
2. **Deploy ASCS and ERS** for high availability
3. **Size appropriately** - start with recommended sizes
4. **Use static IPs** for all production systems
5. **Plan instance numbers** before deployment
6. **Enable backups** on HANA database
7. **Use cloud-init** for consistent configuration
8. **Tag resources** for organization and cost tracking
9. **Generate Ansible inventory** for automation
10. **Test in non-prod** before production deployment

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| nutanix | ~> 1.9.0 |

## Dependencies

This module uses:
- `../sap-hana` - For HANA database deployment
- `../sap-netweaver` - For application server deployment

## References

- [SAP S/4HANA Installation Guide](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE)
- [SAP on Nutanix Best Practices](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2065-SAP-HANA-on-Nutanix)
- [SAP Note 1944799](https://me.sap.com/notes/1944799) - SAP HANA on Nutanix

