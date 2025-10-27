# Example: SAP HANA Single Node Deployment

This example demonstrates deploying a single-node SAP HANA database on Nutanix infrastructure.

**DISCLAIMER**: This is an example configuration and is NOT officially supported by SAP SE or Nutanix, Inc. Always validate against official documentation before production use.

## Architecture

```
┌─────────────────────────────────┐
│   SAP HANA Database (Single)    │
│                                 │
│   SID: HDB                      │
│   Instance: 00                  │
│   Size: M (256 GB, 32 vCPUs)   │
│                                 │
│   Storage:                      │
│   - OS: 100 GB                  │
│   - Data: 256 GB (4 disks)      │
│   - Log: 129 GB (3 disks)       │
│   - Shared: 256 GB              │
│   - Backup: 512 GB              │
│                                 │
│   IP: 10.10.10.50               │
└─────────────────────────────────┘
```

## Prerequisites

1. Nutanix cluster with:
   - Available capacity: ~1.3 TB storage, 32 vCPUs, 256 GB RAM
   - Network subnet configured
   - OS image uploaded (SLES 15 SP5 for SAP or RHEL 8.6+)

2. Terraform installed (>= 1.5.0)

3. Access credentials for Nutanix Prism

## Quick Start

### 1. Configure Variables

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Plan Deployment

```bash
terraform plan
```

### 4. Deploy

```bash
terraform apply
```

### 5. Get Connection Info

```bash
terraform output connection_info
```

## Customization

### Change System Size

Modify the `sap_system_size` in `main.tf`:

```hcl
sap_system_size = "L"  # Options: XS, S, M, L, XL
```

| Size | Memory | vCPUs | Use Case |
|------|--------|-------|----------|
| XS   | 64 GB  | 8     | Dev/Sandbox |
| S    | 128 GB | 16    | Small Prod |
| M    | 256 GB | 32    | Medium Prod |
| L    | 512 GB | 64    | Large Prod |
| XL   | 1024 GB | 96   | Very Large |

### Custom Sizing

For custom sizes:

```hcl
module "hana_database" {
  source = "../../modules/sap-hana"
  
  sap_system_size = "custom"
  memory_gb       = 384
  num_vcpus       = 48
  
  # Custom storage
  data_disk_count   = 5
  data_disk_size_gb = 100
  log_disk_count    = 3
  log_disk_size_gb  = 150
  # ...
}
```

### Override Storage Sizes

```hcl
module "hana_database" {
  source = "../../modules/sap-hana"
  
  sap_system_size      = "M"
  
  # Override calculated sizes
  data_disk_size_gb    = 100  # Instead of auto-calculated
  log_disk_size_gb     = 80
  shared_disk_size_gb  = 300
  backup_disk_size_gb  = 1000
  # ...
}
```

## Post-Deployment

### 1. Verify VM

```bash
# Get VM details
terraform output hana_vm_details

# Check storage layout
terraform output hana_storage
```

### 2. SSH to VM

```bash
# Get IP address
VM_IP=$(terraform output -json hana_vm_details | jq -r '.ip_address')

# SSH to VM
ssh root@${VM_IP}
```

### 3. Configure OS (Manual Steps)

```bash
# On the VM:

# 1. Configure storage
# Create LVM volumes for HANA directories

# 2. Apply SAP tuning
tuned-adm profile sap-hana

# 3. Install SAP HANA
# Follow SAP HANA installation guide
```

### 4. Or Use Ansible

```bash
# Generate Ansible inventory
terraform output -raw ansible_host_vars > inventory

# Run SAP HANA installation playbook
ansible-playbook -i inventory install_hana.yml
```

## Maintenance

### Scale Up (Vertical Scaling)

1. Stop HANA database
2. Update `sap_system_size` in terraform.tfvars
3. Run `terraform apply`
4. Start HANA database

### Add Storage

```hcl
# Add more data disks
data_disk_count = 6  # Was 4

# Or increase disk sizes
data_disk_size_gb = 150  # Was 64
```

### Backup Configuration

The module creates a backup disk by default. To disable:

```hcl
enable_backup_disk = false
```

## Cost Estimation

For a Medium (M) size system:
- Storage: ~1.3 TB
- RAM: 256 GB
- vCPUs: 32

Estimate your costs based on Nutanix licensing and infrastructure.

## SAP Notes Compliance

This example implements:
- ✅ SAP Note 1944799 (HANA on Nutanix)
- ✅ SAP Note 2205917 (Storage requirements)
- ✅ SAP Note 2015553 (Linux prerequisites)

## Troubleshooting

### Issue: Insufficient Resources

**Error**: Not enough CPU/Memory available

**Solution**: 
- Check cluster capacity
- Reduce `sap_system_size`
- Or use different cluster

### Issue: Image Not Found

**Error**: OS image not found

**Solution**:
- Verify image name: `terraform output os_image_name`
- Upload image to Nutanix
- Or update `os_image_name` variable

### Issue: IP Address Conflict

**Error**: IP address already in use

**Solution**:
- Change `hana_ip_address` in terraform.tfvars
- Or use DHCP (set `ip_address = ""`)

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

## References

- [SAP HANA Installation Guide](https://help.sap.com/docs/SAP_HANA_PLATFORM)
- [Nutanix SAP Best Practices](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2065-SAP-HANA-on-Nutanix)
- [Main Module Documentation](../../modules/sap-hana/README.md)

