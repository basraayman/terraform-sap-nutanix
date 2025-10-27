# Example: SAP S/4HANA Distributed System

This example demonstrates deploying a complete, production-ready SAP S/4HANA system with distributed architecture and high availability.

**DISCLAIMER**: This is an example configuration and is NOT officially supported by SAP SE or Nutanix, Inc. Always validate against official documentation before production use.

## Architecture

```
                    ┌─────────────────┐
                    │  Web Dispatcher │
                    │   10.10.10.30   │
                    └────────┬────────┘
                             │
         ┌───────────────────┴───────────────────┐
         │                                       │
    ┌────▼────┐                            ┌────▼────┐
    │   PAS   │                            │  AAS-01 │
    │ 10.10.  │                            │ 10.10.  │
    │ 10.20   │                            │ 10.21   │
    └────┬────┘                            └────┬────┘
         │                                      │
         │         ┌──────────┐                 │
         └─────────►  AAS-02  ◄─────────────────┘
                   │ 10.10.10.22 │
                   └──────┬──────┘
                          │
              ┌───────────┴───────────┐
              │                       │
         ┌────▼────┐            ┌─────▼────┐
         │  ASCS   │            │   ERS    │
         │10.10.   │            │ 10.10.   │
         │10.11    │            │ 10.12    │
         └────┬────┘            └──────────┘
              │
         ┌────▼────────┐
         │  HANA DB    │
         │  10.10.10.10│
         │  512 GB RAM │
         │  64 vCPUs   │
         └─────────────┘
```

## Components

| Component | Hostname | IP | vCPUs | Memory | Purpose |
|-----------|----------|-------|-------|--------|---------|
| HANA DB | s4p-db | 10.10.10.10 | 64 | 512 GB | Database |
| ASCS | s4p-ascs | 10.10.10.11 | 8 | 32 GB | Central Services |
| ERS | s4p-ers | 10.10.10.12 | 8 | 32 GB | Enqueue Replication |
| PAS | s4p-pas | 10.10.10.20 | 32 | 128 GB | Primary App Server |
| AAS-01 | s4p-aas01 | 10.10.10.21 | 32 | 128 GB | Additional App Server |
| AAS-02 | s4p-aas02 | 10.10.10.22 | 32 | 128 GB | Additional App Server |
| Web Disp | s4p-wdp | 10.10.10.30 | 16 | 32 GB | Load Balancer |

**Total Resources:**
- VMs: 7
- vCPUs: 200
- Memory: 896 GB
- Storage: ~4 TB

## Prerequisites

### Nutanix Infrastructure
- Available capacity for 7 VMs
- Network subnet with available IPs (10.10.10.10-30)
- OS image uploaded (SLES 15 SP5 for SAP or RHEL 8.6+)

### Tools
- Terraform >= 1.5.0
- SSH access
- Nutanix Prism credentials

## Quick Start

### 1. Configure

```bash
cd examples/s4hana-distributed
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars
```

### 2. Deploy

```bash
terraform init
terraform plan
terraform apply
```

Deployment time: ~30-45 minutes

### 3. Review Deployment

```bash
# Get summary
terraform output deployment_summary

# List all VMs
terraform output all_systems

# Get connection info
terraform output connection_info
```

## Post-Deployment Steps

### 1. Verify Infrastructure

```bash
# Check all VMs are running
terraform output all_systems | jq

# Test SSH connectivity
for ip in $(terraform output -json all_systems | jq -r '.[].ip_address'); do
  echo "Testing $ip..."
  ssh -o ConnectTimeout=5 root@$ip hostname
done
```

### 2. Configure Storage (on each VM)

```bash
# Example for HANA database
ssh root@$(terraform output -json database_info | jq -r '.ip_address')

# Create LVM volumes for HANA
# This should be done via Ansible in production
```

### 3. Install SAP Software

Option A: Manual Installation
- Follow SAP installation guides for each component

Option B: Automated with Ansible
```bash
# Generated Ansible inventory is ready
ansible-playbook -i $(terraform output -raw ansible_inventory_location) \
  install-s4hana.yml
```

### 4. Configure High Availability

For ASCS/ERS high availability:
```bash
# Set up pacemaker cluster between ASCS and ERS nodes
# This typically requires:
# - Shared storage for /sapmnt
# - Cluster software (pacemaker)
# - Fence agents
```

## Customization

### Change System Size

Edit `main.tf` to adjust VM sizing:

```hcl
# Smaller system
hana_vm_config = {
  memory_gb = 256  # Instead of 512
  num_vcpus = 32   # Instead of 64
  system_size = "M"
}

pas_vm_config = {
  memory_gb = 64   # Instead of 128
  num_vcpus = 16   # Instead of 32
}
```

### Add More Application Servers

```hcl
additional_app_servers = [
  # ... existing ...
  {
    memory_gb   = 128
    num_vcpus   = 32
    ip_address  = "10.10.10.23"
  },
  {
    memory_gb   = 128
    num_vcpus   = 32
    ip_address  = "10.10.10.24"
  }
]
```

### Remove Web Dispatcher

```hcl
deploy_web_dispatcher = false
```

### Disable ERS (No HA)

```hcl
deploy_ers = false
```

## Scaling

### Scale Up (Vertical)

1. Stop SAP system
2. Update memory/CPU in `main.tf`
3. Run `terraform apply`
4. Start SAP system

### Scale Out (Horizontal)

Add more application servers:
```hcl
additional_app_servers = [
  # Add more entries
]
```

Run `terraform apply` - new servers are added without affecting existing ones.

## High Availability

### ASCS/ERS Cluster

This deployment includes ASCS and ERS on separate VMs for HA:

```bash
# Configure pacemaker cluster
ssh root@10.10.10.11  # ASCS node

# Install cluster software
zypper install -t pattern ha_sles

# Configure cluster (both nodes)
# ... cluster setup steps ...
```

### Database HA

For HANA System Replication (HSR):
- Deploy second HANA instance
- Configure replication
- Set up automatic failover

```hcl
# Add to main.tf (future enhancement)
# Secondary HANA for HSR
```

## Monitoring

### Check Resource Usage

```bash
# Get VM UUIDs
terraform output -json all_systems | jq -r '.[].vm_uuid'

# Monitor via Nutanix Prism
# Check: CPU, Memory, Storage, Network
```

### SAP Monitoring

After SAP installation:
```bash
# SAP system status
ssh root@10.10.10.20  # PAS
su - s4padm
sapcontrol -nr 00 -function GetProcessList
```

## Maintenance

### Backup Strategy

1. **HANA Database**: Use HANA backup tools
2. **Application Servers**: Nutanix snapshots
3. **Shared Storage**: Regular filesystem backups

### Updates

```bash
# Update OS packages
ansible all -i inventory/s4p -m zypper -a "name='*' state=latest"

# SAP kernel updates
# Follow SAP procedures
```

## Troubleshooting

### Issue: Deployment Fails

Check Terraform errors:
```bash
terraform show
terraform refresh
```

Common issues:
- Insufficient resources
- Network configuration
- Image not found
- IP conflicts

### Issue: Can't SSH to VMs

```bash
# Check VM status in Prism
# Verify network connectivity
# Check security groups/firewall
```

### Issue: Performance Problems

```bash
# Check SAP tuning
tuned-adm active

# Verify storage performance
fio --name=test --ioengine=libaio --rw=randrw --bs=64k --size=1G

# Check SAP Early Watch Report
```

## Cost Estimation

Resources for this deployment:
- 200 vCPUs
- 896 GB RAM
- ~4 TB storage

Calculate based on your Nutanix licensing model.

## Production Readiness Checklist

- [ ] Sizing validated with SAP Quick Sizer
- [ ] HA configured for ASCS/ERS
- [ ] Database backup configured
- [ ] Monitoring setup (SAP Solution Manager / third-party)
- [ ] Disaster recovery plan
- [ ] Network security (firewall rules)
- [ ] Access control (user management)
- [ ] Documentation updated
- [ ] Team training completed
- [ ] Go-live support arranged

## Cleanup

To remove the entire system:

```bash
# This will destroy all 7 VMs and resources
terraform destroy
```

**Warning**: This is irreversible! Back up all data first.

## Next Steps

1. **Install SAP Software**: Use SWPM (Software Provisioning Manager)
2. **Configure Monitoring**: Set up SAP Solution Manager
3. **Apply Security**: Implement security baseline
4. **Performance Tuning**: Run HWCCT, apply SAP notes
5. **Backup Setup**: Configure automated backups
6. **HA Testing**: Test failover scenarios
7. **Load Testing**: Validate performance

## References

- [SAP S/4HANA Installation Guide](https://help.sap.com/docs/SAP_S4HANA_ON-PREMISE)
- [SAP HANA System Replication](https://help.sap.com/docs/SAP_HANA_PLATFORM/6b94445c94ae495c83a19646e7c3fd56/b74e16a9e09541749a745f41246a065e.html)
- [Nutanix SAP Best Practices](https://portal.nutanix.com/page/documents/solutions/details?targetId=BP-2065-SAP-HANA-on-Nutanix)
- [Main Module Documentation](../../modules/sap-s4hana/README.md)

