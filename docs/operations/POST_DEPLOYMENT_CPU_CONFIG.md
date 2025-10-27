# Post-Deployment CPU Configuration for SAP HANA

## Important Notice

The Nutanix Terraform provider does **not currently support** the following advanced CPU configuration options required for optimal SAP HANA performance:

- vNUMA (Virtual NUMA) configuration
- CPU pinning (hard affinity)
- Threads per core configuration

These settings must be configured manually after VM deployment using Nutanix `acli` commands.

## Required Post-Deployment Steps

### Step 1: Power Off the VM

```bash
# SSH to any Nutanix CVM in the cluster
ssh nutanix@<cvm-ip>

# Power off the VM (required for CPU changes)
acli vm.off <vm_name>
```

### Step 2: Configure Hyper-Threading

For SAP HANA, it is **strongly recommended** to disable Hyper-Threading:

```bash
# Disable Hyper-Threading (recommended for SAP HANA)
acli vm.update <vm_name> num_threads_per_core=1

# If Hyper-Threading must be enabled (not recommended)
acli vm.update <vm_name> num_threads_per_core=2
```

### Step 3: Configure vNUMA and CPU Pinning

Configure the CPU topology with NUMA awareness and pinning:

```bash
acli vm.update <vm_name> \
  num_vcpus=<number_of_sockets> \
  num_vnuma_nodes=<number_of_numa_nodes> \
  num_cores_per_vcpu=<cores_per_socket> \
  vcpu_hard_pin=True
```

### Step 4: Power On the VM

```bash
acli vm.on <vm_name>
```

## Configuration Examples

### Example 1: Small System (64 GB, 8 vCPUs)

```bash
# Single socket, single NUMA node
acli vm.off hana-dev-01
acli vm.update hana-dev-01 num_threads_per_core=1
acli vm.update hana-dev-01 \
  num_vcpus=1 \
  num_vnuma_nodes=1 \
  num_cores_per_vcpu=8 \
  vcpu_hard_pin=True
acli vm.on hana-dev-01
```

### Example 2: Medium System (256 GB, 32 vCPUs)

```bash
# 2 sockets, 2 NUMA nodes, 16 cores per socket
acli vm.off hana-prod-01
acli vm.update hana-prod-01 num_threads_per_core=1
acli vm.update hana-prod-01 \
  num_vcpus=2 \
  num_vnuma_nodes=2 \
  num_cores_per_vcpu=16 \
  vcpu_hard_pin=True
acli vm.on hana-prod-01
```

### Example 3: Large System (512 GB, 64 vCPUs)

```bash
# 2 sockets, 2 NUMA nodes, 32 cores per socket
acli vm.off hana-prod-02
acli vm.update hana-prod-02 num_threads_per_core=1
acli vm.update hana-prod-02 \
  num_vcpus=2 \
  num_vnuma_nodes=2 \
  num_cores_per_vcpu=32 \
  vcpu_hard_pin=True
acli vm.on hana-prod-02
```

### Example 4: Very Large System (1024 GB, 96 vCPUs)

```bash
# 2 sockets, 2 NUMA nodes, 48 cores per socket
acli vm.off hana-prod-xl
acli vm.update hana-prod-xl num_threads_per_core=1
acli vm.update hana-prod-xl \
  num_vcpus=2 \
  num_vnuma_nodes=2 \
  num_cores_per_vcpu=48 \
  vcpu_hard_pin=True
acli vm.on hana-prod-xl
```

## NUMA Configuration Guidelines

Per SAP Note 2686722:

| Memory Size | Recommended Config |
|-------------|-------------------|
| < 256 GB    | 1 socket, 1 NUMA node |
| 256-512 GB  | 2 sockets, 2 NUMA nodes |
| > 512 GB    | 2 sockets, 2 NUMA nodes |

**Key Principle**: Distribute vCPUs evenly across sockets and NUMA nodes to match physical NUMA topology.

## Verification

After configuration, verify the settings:

```bash
# Check VM CPU configuration
acli vm.get <vm_name>

# Look for these fields:
# - num_vcpus
# - num_cores_per_vcpu
# - num_threads_per_core
# - num_vnuma_nodes
# - vcpu_hard_pin
```

From within the VM (after boot):

```bash
# Check NUMA configuration
numactl --hardware

# Check CPU topology
lscpu

# Verify cores and threads
cat /proc/cpuinfo | grep -E "processor|physical id|core id" | head -20
```

## Automation Options

### Option 1: Terraform null_resource with local-exec

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
          num_cores_per_vcpu=16 \
          vcpu_hard_pin=True
        acli vm.on ${module.hana_database.vm_name}
      ENDSSH
    EOT
  }
}
```

### Option 2: Ansible Playbook

```yaml
---
- name: Configure SAP HANA CPU settings
  hosts: nutanix_cvm
  tasks:
    - name: Power off VM
      shell: acli vm.off {{ vm_name }}
      
    - name: Wait for VM to power off
      pause:
        seconds: 10
      
    - name: Disable Hyper-Threading
      shell: acli vm.update {{ vm_name }} num_threads_per_core=1
      
    - name: Configure vNUMA and CPU pinning
      shell: |
        acli vm.update {{ vm_name }} \
          num_vcpus={{ num_sockets }} \
          num_vnuma_nodes={{ numa_nodes }} \
          num_cores_per_vcpu={{ cores_per_socket }} \
          vcpu_hard_pin=True
      
    - name: Power on VM
      shell: acli vm.on {{ vm_name }}
```

### Option 3: Shell Script

```bash
#!/bin/bash
# configure_hana_cpu.sh

VM_NAME="$1"
NUM_SOCKETS="$2"
NUMA_NODES="$3"
CORES_PER_SOCKET="$4"
CVM_IP="$5"

ssh nutanix@${CVM_IP} << ENDSSH
  echo "Configuring CPU for ${VM_NAME}..."
  acli vm.off ${VM_NAME}
  sleep 10
  
  echo "Disabling Hyper-Threading..."
  acli vm.update ${VM_NAME} num_threads_per_core=1
  
  echo "Configuring vNUMA and CPU pinning..."
  acli vm.update ${VM_NAME} \
    num_vcpus=${NUM_SOCKETS} \
    num_vnuma_nodes=${NUMA_NODES} \
    num_cores_per_vcpu=${CORES_PER_SOCKET} \
    vcpu_hard_pin=True
  
  echo "Powering on ${VM_NAME}..."
  acli vm.on ${VM_NAME}
  
  echo "Configuration complete!"
ENDSSH
```

Usage:
```bash
./configure_hana_cpu.sh hana-prod-01 2 2 32 10.10.10.39
```

## Important Notes

1. **VM Must Be Powered Off**: All CPU configuration changes require the VM to be powered off.

2. **Hyper-Threading**: Disable Hyper-Threading (`num_threads_per_core=1`) for SAP HANA per SAP best practices.

3. **CPU Pinning**: Always enable CPU pinning (`vcpu_hard_pin=True`) for production SAP HANA systems.

4. **NUMA Alignment**: Ensure vNUMA nodes match physical NUMA topology for optimal performance.

5. **Socket Distribution**: Distribute cores evenly across sockets (e.g., 64 vCPUs = 2 sockets × 32 cores).

6. **Validation**: Always verify configuration after changes using `acli vm.get` and in-guest tools.

7. **Terraform Provider Limitation**: These settings are not yet supported in the Nutanix Terraform provider as of version 1.9.x.

## SAP Note References

- **SAP Note 2686722**: SAP HANA virtualized on Nutanix AOS
- **SAP Note 1944799**: SAP HANA Guidelines for SLES Operating System Installation

## Support

For issues with acli commands:
- Consult Nutanix documentation
- Contact Nutanix support
- Review Nutanix portal documentation

For SAP HANA configuration:
- Consult SAP Note 2686722
- Contact SAP support
- Use SAP Hardware Configuration Check Tool (HWCCT)

---

**DISCLAIMER**: This is an unofficial guide. Always validate against official Nutanix and SAP documentation before production use.

