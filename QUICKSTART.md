# Quick Start Guide

Get up and running with Terraform SAP on Nutanix in 5 minutes.

## Important Notice

**DISCLAIMER**: This is a private initiative and is NOT officially supported by SAP SE or Nutanix, Inc. This project is provided as-is without warranty. For official support, please contact SAP and Nutanix through their standard support channels.

**Please read the full [DISCLAIMER](./DISCLAIMER.md) before using this project.**

## Prerequisites

- [x] Terraform >= 1.5.0
- [x] Nutanix cluster access
- [x] OS image uploaded (SLES 15 SP5 or RHEL 8.6+)
- [x] Network subnet configured  

## Installation

```bash
# Clone or copy the repository
cd /Users/bas/git/terraform-sap-nutanix

# Initialize Terraform
terraform init
```

## Choose Your Scenario

### 1. SAP HANA Database Only

**Use Case**: Standalone HANA database for development or BW/4HANA

```bash
cd examples/hana-single-node
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

**What You Get**:
- 1 VM with SAP HANA sizing
- Optimized storage layout
- Ready for HANA installation

**Time**: ~10 minutes

**Note**: After deployment, configure vNUMA and CPU pinning using acli commands. See [POST_DEPLOYMENT_CPU_CONFIG.md](./docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md).

---

### 2. Complete SAP S/4HANA System

**Use Case**: Production S/4HANA with HA and scale-out

```bash
cd examples/s4hana-distributed
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
terraform init
terraform plan
terraform apply
```

**What You Get**:
- 7 VMs (DB, ASCS, ERS, PAS, 2xAAS, WDP)
- High availability ready
- Load balanced
- Ansible inventory generated

**Time**: ~30 minutes

---

### 3. Custom Configuration

**Use Case**: Specific requirements

```bash
# Use root module directly
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
# Uncomment and configure modules in main.tf
terraform init
terraform apply
```

## Essential Configuration

### Minimum terraform.tfvars

```hcl
# Nutanix connection
nutanix_username = "admin"
nutanix_password = "your-password"
nutanix_endpoint = "10.10.10.39"

# Infrastructure
cluster_name = "your-cluster"
subnet_name  = "your-subnet"

# SAP settings
environment = "prod"
sap_landscape_name = "sap-prod"
```

## Module Usage

### SAP HANA Module

```hcl
module "hana" {
  source = "./modules/sap-hana"
  
  vm_name       = "hanadb01"
  cluster_uuid  = var.cluster_uuid
  subnet_uuid   = var.subnet_uuid
  
  hana_sid      = "HDB"
  sap_system_size = "M"  # XS, S, M, L, XL
  
  os_image_name = "SLES15-SP5-SAP"
}
```

### SAP NetWeaver Module

```hcl
module "app" {
  source = "./modules/sap-netweaver"
  
  vm_name       = "sapapp01"
  cluster_uuid  = var.cluster_uuid
  subnet_uuid   = var.subnet_uuid
  
  sap_sid       = "NPL"
  instance_type = "PAS"  # PAS, AAS, ASCS, ERS, WDP
  
  memory_gb     = 64
  num_vcpus     = 16
  
  os_image_name = "SLES15-SP5-SAP"
}
```

### SAP S/4HANA Module

```hcl
module "s4hana" {
  source = "./modules/sap-s4hana"
  
  cluster_uuid = var.cluster_uuid
  subnet_uuid  = var.subnet_uuid
  
  sap_sid = "S4P"
  
  hana_vm_config = {
    memory_gb = 512
    num_vcpus = 64
  }
  
  pas_vm_config = {
    memory_gb = 64
    num_vcpus = 16
  }
}
```

## Common Commands

```bash
# Initialize
terraform init

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Plan deployment
terraform plan

# Apply changes
terraform apply

# Show outputs
terraform output

# Destroy everything
terraform destroy
```

## Quick Sizing Guide

| Workload | Size | RAM | vCPUs | Use For |
|----------|------|-----|-------|---------|
| Dev/Test | XS | 64 GB | 8 | Development |
| QA | S | 128 GB | 16 | Testing |
| Small Prod | M | 256 GB | 32 | <100 users |
| Medium Prod | L | 512 GB | 64 | 100-500 users |
| Large Prod | XL | 1024 GB | 96 | >500 users |

## Outputs You'll Need

```bash
# Get VM IP addresses
terraform output -json | jq -r '.all_vms.value'

# Get connection info
terraform output connection_info

# Get Ansible inventory location
terraform output ansible_inventory_path
```

## Next Steps After Deployment

### 1. Verify Infrastructure
```bash
# SSH to HANA database
ssh root@$(terraform output -json | jq -r '.hana_database.value.ip_address')
```

### 2. Configure Storage
```bash
# On each VM, set up LVM and mount points
# This should be done via Ansible in production
```

### 3. Install SAP Software
```bash
# Option A: Manual with SWPM
# Option B: Automated with Ansible
ansible-playbook -i $(terraform output -raw ansible_inventory_path) install.yml
```

### 4. Configure CPU Settings (Required for Production)
```bash
# On Nutanix CVM - Configure vNUMA and CPU pinning
# See docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md for details
acli vm.off <vm_name>
acli vm.update <vm_name> num_threads_per_core=1
acli vm.update <vm_name> \
  num_vcpus=2 \
  num_vnuma_nodes=2 \
  num_cores_per_vcpu=16 \
  vcpu_hard_pin=True
acli vm.on <vm_name>
```

### 5. Apply SAP Tuning
```bash
# On each VM
tuned-adm profile sap-hana  # or sap-netweaver
```

## Troubleshooting

### Can't Connect to Nutanix
```bash
# Test connection
curl -k https://${NUTANIX_ENDPOINT}:9440/api/nutanix/v3/clusters/list \
  -u ${USERNAME}:${PASSWORD} -X POST -d '{}'
```

### Image Not Found
```bash
# List available images
terraform console
> data.nutanix_image.os_image
```

### Insufficient Resources
```bash
# Check cluster capacity in Prism
# Or reduce sizing: sap_system_size = "S"
```

### IP Conflict
```bash
# Use DHCP instead
ip_address = ""

# Or change IP range
ip_base = "10.10.20"  # Different subnet
```

## Getting Help

1. **Check Documentation**
   - [Main README](./README.md)
   - [Module READMEs](./modules/)
   - [Examples](./examples/)

2. **Review SAP Notes**
   - [SAP Notes Library](./sap-notes/README.md)

3. **Example Configurations**
   - [HANA Single Node](./examples/hana-single-node/)
   - [S/4HANA Distributed](./examples/s4hana-distributed/)

4. **Common Issues**
   - Check terraform.tfvars values
   - Verify Nutanix cluster access
   - Confirm image availability
   - Check network configuration

## Cheat Sheet

```bash
# Quick deploy HANA (M size)
cd examples/hana-single-node && \
cp terraform.tfvars.example terraform.tfvars && \
terraform init && terraform apply -auto-approve

# Quick deploy S/4HANA
cd examples/s4hana-distributed && \
cp terraform.tfvars.example terraform.tfvars && \
terraform init && terraform apply

# Get all IPs
terraform output -json | jq -r '.. | .ip_address? // empty'

# Destroy specific module
terraform destroy -target=module.hana_database

# Re-create without destroying
terraform apply -replace=module.hana_database.nutanix_virtual_machine.sap_hana
```

## Best Practices

- [x] **Use static IPs** for production
- [x] **Enable backup disks** for HANA
- [x] **Deploy ASCS/ERS** for HA
- [x] **Use T-shirt sizes** unless custom needed
- [x] **Generate Ansible inventory** for automation
- [x] **Tag resources** for organization
- [x] **Test in dev** before production  

## Production Checklist

Before going to production:

- [ ] Sizing validated with SAP Quick Sizer
- [ ] Static IPs configured
- [ ] Backup strategy defined
- [ ] HA configured (if required)
- [ ] Network security reviewed
- [ ] Monitoring setup
- [ ] Disaster recovery plan
- [ ] Documentation updated
- [ ] Team training completed
- [ ] Change management approved

## Quick Reference Links

- [Nutanix Provider Docs](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs)
- [SAP on Nutanix Best Practices](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2065-SAP-HANA-on-Nutanix)
- [SAP Note 1944799](https://me.sap.com/notes/1944799)
- [Terraform Best Practices](https://www.terraform.io/docs/language/index.html)

---

Ready to deploy? Start with an example:

```bash
cd examples/hana-single-node
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars, then:
terraform init && terraform apply
```

