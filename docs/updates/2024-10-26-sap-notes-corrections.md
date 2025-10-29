# SAP Notes Update - Corrected Descriptions and Added vNUMA Configuration

## Date: October 27, 2024

## Summary

This update corrects SAP note descriptions, adds support for additional SAP notes (RHEL-specific and Nutanix virtualization), removes an incorrect Azure-specific reference, and documents the requirement for post-deployment CPU configuration.

## Changes Made

### 1. Corrected SAP Note Descriptions

| SAP Note | Previous Description | Updated Description |
|----------|---------------------|---------------------|
| 1944799 | SAP HANA Guidelines for Nutanix Systems | SAP HANA Guidelines for SLES Operating System Installation |
| 1900823 | SAP HANA Storage Requirements (sizing formulas) | SAP HANA Storage Connector API |

### 2. Added New SAP Notes

#### SAP Note 2686722 - SAP HANA virtualized on Nutanix AOS
- **Focus**: Virtualization-specific settings for SAP HANA on Nutanix AHV
- **Key Requirements**:
  - 100% CPU and memory reservation
  - vNUMA configuration
  - CPU pinning (hard affinity)
  - Hyper-Threading recommendations (disable for HANA)
  - Nutanix-specific storage and network settings

#### SAP Note 2772999 - Red Hat Enterprise Linux 8.x: Installation and Configuration
- **Focus**: RHEL 8.x specific settings for SAP systems
- **Key Requirements**:
  - RHEL 8 package requirements
  - tuned-profiles-sap-hana
  - Kernel parameters for RHEL 8
  - SELinux configuration

#### SAP Note 3108316 - Red Hat Enterprise Linux 9.x: Installation and Configuration
- **Focus**: RHEL 9.x specific settings for SAP systems
- **Key Requirements**:
  - RHEL 9 package requirements
  - Updated tuned profiles
  - Modern kernel parameters
  - Enhanced security settings

### 3. Removed Incorrect Reference

**SAP Note 2015553** has been removed as it contains Azure-specific instructions that are not applicable to Nutanix deployments.

### 4. Added Post-Deployment CPU Configuration Documentation

#### Issue Identified
The Nutanix Terraform provider (v1.9.x) does **NOT support** the following advanced CPU configuration options:
- vNUMA (Virtual NUMA nodes)
- CPU pinning (vcpu_hard_pin)
- Threads per core (Hyper-Threading control)

#### Solution Implemented
Created comprehensive documentation for post-deployment configuration using Nutanix `acli` commands.

**New File**: `POST_DEPLOYMENT_CPU_CONFIG.md`

#### Required acli Commands

```bash
# Power off VM (required for CPU changes)
acli vm.off <vm_name>

# Disable Hyper-Threading (recommended for SAP HANA)
acli vm.update <vm_name> num_threads_per_core=1

# Configure vNUMA and CPU pinning
acli vm.update <vm_name> \
  num_vcpus=<number_of_sockets> \
  num_vnuma_nodes=<number_of_numa_nodes> \
  num_cores_per_vcpu=<cores_per_socket> \
  vcpu_hard_pin=True

# Power on VM
acli vm.on <vm_name>
```

#### Configuration Examples

**Medium System (256 GB, 32 vCPUs):**
```bash
acli vm.update hana-prod \
  num_vcpus=2 \
  num_vnuma_nodes=2 \
  num_cores_per_vcpu=16 \
  vcpu_hard_pin=True \
  num_threads_per_core=1
```

**Large System (512 GB, 64 vCPUs):**
```bash
acli vm.update hana-prod \
  num_vcpus=2 \
  num_vnuma_nodes=2 \
  num_cores_per_vcpu=32 \
  vcpu_hard_pin=True \
  num_threads_per_core=1
```

### 5. NUMA Configuration Guidelines

Per SAP Note 2686722:

| Memory Size | Sockets | NUMA Nodes | Cores per Socket |
|-------------|---------|------------|------------------|
| < 256 GB    | 1       | 1          | All cores |
| 256-512 GB  | 2       | 2          | Half cores each |
| > 512 GB    | 2       | 2          | Half cores each |

**Best Practices**:
- Disable Hyper-Threading for SAP HANA (`num_threads_per_core=1`)
- Enable CPU pinning for production (`vcpu_hard_pin=True`)
- Match vNUMA nodes to physical NUMA topology
- Distribute cores evenly across sockets

### 6. Files Created

1. **sap-notes/sap-note-2686722.tf**
   - Complete implementation of SAP Note 2686722
   - Virtualization requirements
   - acli command templates
   - NUMA recommendations by system size
   - Performance tuning guidelines

2. **POST_DEPLOYMENT_CPU_CONFIG.md**
   - Detailed step-by-step instructions
   - Configuration examples for all T-shirt sizes
   - Verification procedures
   - Automation options (Terraform, Ansible, Shell script)
   - NUMA configuration guidelines
   - Troubleshooting tips

3. **SAP_NOTES_UPDATE.md** (this file)
   - Summary of all changes
   - Migration guide
   - Reference information

### 7. Updated Files

- **README.md**: Added post-deployment configuration notice, updated SAP notes table
- **modules/sap-hana/main.tf**: Updated SAP note references in comments
- **modules/sap-hana/README.md**: Added post-deployment section with examples
- **sap-notes/README.md**: Updated all SAP note descriptions, removed 2015553
- **CHANGELOG.md**: Added new SAP notes to implementation list
- **QUICKSTART.md**: Added CPU configuration step to post-deployment

## Updated SAP Notes Table

| SAP Note | Description | Module | Link |
|----------|-------------|--------|------|
| 1944799 | SAP HANA Guidelines for SLES Operating System Installation | sap-hana | [Link](https://me.sap.com/notes/1944799) |
| 1900823 | SAP HANA Storage Connector API | sap-hana | [Link](https://me.sap.com/notes/1900823) |
| 2686722 | SAP HANA virtualized on Nutanix AOS | sap-hana | [Link](https://me.sap.com/notes/2686722) |
| 2205917 | SAP HANA: OS Settings for SLES 12 | all | [Link](https://me.sap.com/notes/2205917) |
| 2684254 | SAP HANA: OS Settings for SLES 15 | all | [Link](https://me.sap.com/notes/2684254) |
| 2772999 | Red Hat Enterprise Linux 8.x: Installation and Configuration | all | [Link](https://me.sap.com/notes/2772999) |
| 3108316 | Red Hat Enterprise Linux 9.x: Installation and Configuration | all | [Link](https://me.sap.com/notes/3108316) |

## Impact on Deployments

### Production Systems

**CRITICAL**: Production SAP HANA systems **MUST** be configured with proper vNUMA and CPU pinning after Terraform deployment.

**Required Steps**:
1. Deploy VM using Terraform
2. Power off VM
3. Run acli commands to configure vNUMA, CPU pinning, and disable Hyper-Threading
4. Power on VM
5. Verify configuration

### Development/Test Systems

While recommended, CPU pinning and vNUMA configuration may be skipped for non-production systems to allow more flexibility in resource allocation.

## Automation Examples

### Terraform null_resource

```hcl
resource "null_resource" "configure_cpu" {
  depends_on = [module.hana_database]
  
  provisioner "local-exec" {
    command = <<-EOT
      ssh nutanix@${var.cvm_ip} << 'ENDSSH'
        acli vm.off ${module.hana_database.vm_name}
        sleep 10
        acli vm.update ${module.hana_database.vm_name} num_threads_per_core=1
        acli vm.update ${module.hana_database.vm_name} \
          num_vcpus=2 \
          num_vnuma_nodes=2 \
          num_cores_per_vcpu=32 \
          vcpu_hard_pin=True
        acli vm.on ${module.hana_database.vm_name}
      ENDSSH
    EOT
  }
}
```

### Ansible Playbook

```yaml
- name: Configure SAP HANA CPU settings
  hosts: nutanix_cvm
  tasks:
    - name: Configure vNUMA and CPU pinning
      shell: |
        acli vm.off {{ vm_name }}
        sleep 10
        acli vm.update {{ vm_name }} num_threads_per_core=1
        acli vm.update {{ vm_name }} \
          num_vcpus={{ num_sockets }} \
          num_vnuma_nodes={{ numa_nodes }} \
          num_cores_per_vcpu={{ cores_per_socket }} \
          vcpu_hard_pin=True
        acli vm.on {{ vm_name }}
```

## Verification

After applying CPU configuration:

```bash
# On Nutanix CVM
acli vm.get <vm_name>

# In the VM (after boot)
numactl --hardware
lscpu
```

## Documentation Updates

All documentation has been updated to reflect:
1. Correct SAP note descriptions
2. Post-deployment CPU configuration requirement
3. Examples for all system sizes
4. Automation options
5. RHEL-specific SAP notes

## Support References

- **SAP Note 2686722**: Authoritative source for SAP HANA on Nutanix virtualization
- **Nutanix acli documentation**: For acli command syntax and options
- **POST_DEPLOYMENT_CPU_CONFIG.md**: Complete implementation guide

## Questions or Issues

For questions about:
- **SAP requirements**: Consult SAP Note 2686722 and contact SAP support
- **Nutanix acli commands**: Consult Nutanix documentation and support
- **Automation**: See examples in POST_DEPLOYMENT_CPU_CONFIG.md

---

**DISCLAIMER**: This is an unofficial community project. Always validate configurations against official SAP and Nutanix documentation before production use.

