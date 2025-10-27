# LVM Storage Configuration for SAP HANA on Nutanix

**DISCLAIMER**: This is an unofficial document and is NOT supported by SAP SE or Nutanix, Inc. Always validate configurations against official documentation before production use.

## Overview

For SAP HANA on Nutanix, we use **Linux LVM (Logical Volume Manager)** instead of RAID to achieve storage striping and optimal performance. Nutanix provides data protection at the storage layer, eliminating the need for VM-level RAID.

## Storage Architecture

### Design Principles

1. **No RAID**: Nutanix handles replication and redundancy at the storage layer (RF2/RF3)
2. **LVM Striping**: Use LVM striping for performance optimization
3. **XFS Filesystem**: Required for SAP HANA with specific mount options
4. **Separate Volumes**: Data, log, and shared must be on separate logical volumes
5. **Full Capacity**: Use 100% of disk capacity for each volume group

## Disk Layout Options

The configuration supports 4 different disk layouts based on the number of **data disks** (excluding the OS disk):

### Option 1: Minimal Configuration (3 data disks)
```
Total disks: 4 (1 OS + 3 data)

OS Disk:     1x disk (OS + root filesystem)
/hana/data:  1x disk  → hanadata VG → LV (no striping)
/hana/log:   1x disk  → hanalog VG  → LV (no striping)
/hana/shared: 1x disk → hanashared VG → LV (no striping)
```

**Use Case**: Development, sandbox, very small systems

### Option 2: Standard Configuration (9 data disks)
```
Total disks: 10 (1 OS + 9 data)

OS Disk:      1x disk (OS + root filesystem)
/hana/data:   4x disks → hanadata VG → LV (4-way stripe, 1MB stripe size)
/hana/log:    4x disks → hanalog VG  → LV (4-way stripe, 1MB stripe size)
/hana/shared: 1x disk  → hanashared VG → LV (no striping)
```

**Use Case**: Small to medium production systems, QA systems

### Option 3: Large Configuration (12 data disks)
```
Total disks: 13 (1 OS + 12 data)

OS Disk:      1x disk (OS + root filesystem)
/hana/data:   4x disks → hanadata VG → LV (4-way stripe, 1MB stripe size)
/hana/log:    4x disks → hanalog VG  → LV (4-way stripe, 1MB stripe size)
/hana/shared: 4x disks → hanashared VG → LV (4-way stripe, 1MB stripe size)
```

**Use Case**: Large production systems, high-performance requirements

### Option 4: Single Disk (1 data disk)
```
Total disks: 2 (1 OS + 1 data)

OS Disk:     1x disk (OS + root filesystem)
Data Disk:   1x disk → Combined VG → Multiple LVs
```

**Use Case**: Testing only, NOT for production

## LVM Configuration Details

### Physical Volumes (PV)

Each data disk is initialized as a physical volume:

```bash
pvcreate /dev/sdb
pvcreate /dev/sdc
pvcreate /dev/sdd
# ... and so on
```

### Volume Groups (VG)

Volume groups are created by combining physical volumes:

#### Example: 12-disk configuration
```bash
# Data volume group (4 disks)
vgcreate hanadata /dev/sdb /dev/sdc /dev/sdd /dev/sde

# Log volume group (4 disks)
vgcreate hanalog /dev/sdf /dev/sdg /dev/sdh /dev/sdi

# Shared volume group (4 disks)
vgcreate hanashared /dev/sdj /dev/sdk /dev/sdl /dev/sdm
```

### Logical Volumes (LV)

Logical volumes are created with **striping enabled** for performance:

```bash
# Create data logical volume with 4-way striping, 1MB stripe size
lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanadata

# Create log logical volume with 4-way striping, 1MB stripe size
lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanalog

# Create shared logical volume with 4-way striping, 1MB stripe size
lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanashared
```

**LVM Parameters Explained**:
- `-i 4`: Number of stripes (matches number of disks in VG)
- `-I1M`: Stripe size of 1MB (1024 KB)
- `-l 100%FREE`: Use 100% of available space
- `-r none`: No RAID (redundancy handled by Nutanix)
- `-n vol`: Logical volume name

### Filesystem Creation

Format all HANA volumes with **XFS filesystem**:

```bash
mkfs.xfs /dev/mapper/hanadata-vol
mkfs.xfs /dev/mapper/hanalog-vol
mkfs.xfs /dev/mapper/hanashared-vol
```

### Mount Configuration

Add entries to `/etc/fstab` with SAP-recommended mount options:

```bash
# /etc/fstab entries for SAP HANA
/dev/mapper/hanadata-vol   /hana/data    xfs  inode64,largeio,swalloc  1 2
/dev/mapper/hanalog-vol    /hana/log     xfs  inode64,largeio,swalloc  1 2
/dev/mapper/hanashared-vol /hana/shared  xfs  inode64,largeio,swalloc  1 2
```

**XFS Mount Options Explained**:
- `inode64`: Allows inode allocation across the entire filesystem (required for filesystems > 1TB)
- `largeio`: Optimizes for large I/O operations (SAP HANA performs large sequential I/O)
- `swalloc`: Stripe width allocation - aligns I/O with stripe geometry

## T-Shirt Sizing Recommendations

| Size | Memory | vCPUs | Data Disks | Log Disks | Shared Disks | Total Data Disks | Total Disks |
|------|--------|-------|------------|-----------|--------------|------------------|-------------|
| XS   | 64 GB  | 8     | 2          | 2         | 1            | 5*               | 6 (1 OS + 5 data) |
| S    | 128 GB | 16    | 2          | 2         | 1            | 5*               | 6 (1 OS + 5 data) |
| M    | 256 GB | 32    | 4          | 4         | 1            | 9                | 10 (1 OS + 9 data) |
| L    | 512 GB | 64    | 4          | 4         | 1            | 9                | 10 (1 OS + 9 data) |
| XL   | 1024 GB| 96    | 4          | 4         | 4            | 12               | 13 (1 OS + 12 data) |

\* For XS/S sizes with 5 total data disks, use the 9-disk configuration pattern but with smaller disk sizes

## Storage Sizing per SAP Note 1900823

| Component     | Formula                                      | Example (256 GB) | Example (1024 GB) |
|---------------|----------------------------------------------|------------------|-------------------|
| /hana/data    | 1.5 × RAM                                   | 384 GB           | 1,536 GB          |
| /hana/log     | 0.5 × RAM (≤512GB) or min 512GB (>512GB)   | 128 GB           | 512 GB            |
| /hana/shared  | MIN(1 × RAM, 1TB)                           | 256 GB           | 1,024 GB          |
| /hana/backup  | 2 × RAM (optional)                          | 512 GB           | 2,048 GB          |

### Disk Sizing Examples

#### 256 GB System (9 data disks)
```
/hana/data:   4 disks × 96 GB  = 384 GB total (1.5 × 256)
/hana/log:    4 disks × 32 GB  = 128 GB total (0.5 × 256)
/hana/shared: 1 disk  × 256 GB = 256 GB total (MIN(256, 1024))
```

#### 1024 GB System (12 data disks)
```
/hana/data:   4 disks × 384 GB = 1,536 GB total (1.5 × 1024)
/hana/log:    4 disks × 128 GB = 512 GB total (minimum for >512GB)
/hana/shared: 4 disks × 256 GB = 1,024 GB total (MIN(1024, 1024))
```

## Terraform Implementation

### Disk Attachment

Terraform creates and attaches disks to the VM:

```hcl
# Data disks (4x for M, L sizes)
dynamic "disk_list" {
  for_each = range(var.data_disk_count)
  content {
    data_source_reference = {
      kind = "image"
      uuid = data.nutanix_image.hana_os.id
    }
    device_properties {
      device_type = "DISK"
      disk_address = {
        device_index = disk_list.key + 1
        adapter_type = "SCSI"
      }
    }
    disk_size_mib = var.data_disk_size_gb * 1024
  }
}
```

### Post-Deployment Configuration

After Terraform creates the VM with attached disks, use **cloud-init** or **Ansible** to configure LVM:

#### Option 1: Cloud-Init Script

```yaml
#cloud-config
runcmd:
  - |
    # Detect data disks (excluding OS disk)
    DISKS=($(lsblk -d -nr -o NAME,TYPE | awk '$2 == "disk" {print $1}' | grep -v sda))
    
    # Create physical volumes
    for disk in "${DISKS[@]}"; do
      pvcreate /dev/$disk
    done
    
    # Create volume groups (12-disk example)
    vgcreate hanadata /dev/${DISKS[0]} /dev/${DISKS[1]} /dev/${DISKS[2]} /dev/${DISKS[3]}
    vgcreate hanalog /dev/${DISKS[4]} /dev/${DISKS[5]} /dev/${DISKS[6]} /dev/${DISKS[7]}
    vgcreate hanashared /dev/${DISKS[8]} /dev/${DISKS[9]} /dev/${DISKS[10]} /dev/${DISKS[11]}
    
    # Create logical volumes with striping
    lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanadata
    lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanalog
    lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanashared
    
    # Format with XFS
    mkfs.xfs /dev/mapper/hanadata-vol
    mkfs.xfs /dev/mapper/hanalog-vol
    mkfs.xfs /dev/mapper/hanashared-vol
    
    # Create mount points
    mkdir -p /hana/{data,log,shared}
    
    # Add to fstab
    echo "/dev/mapper/hanadata-vol /hana/data xfs inode64,largeio,swalloc 1 2" >> /etc/fstab
    echo "/dev/mapper/hanalog-vol /hana/log xfs inode64,largeio,swalloc 1 2" >> /etc/fstab
    echo "/dev/mapper/hanashared-vol /hana/shared xfs inode64,largeio,swalloc 1 2" >> /etc/fstab
    
    # Mount all
    mount -a
```

#### Option 2: Ansible Playbook

Create an Ansible playbook to automate LVM configuration across multiple systems. This approach is recommended for production deployments where you need consistent configuration and auditability.

## Performance Verification

After LVM configuration, verify the setup:

### Check LVM Configuration

```bash
# List physical volumes
pvdisplay

# List volume groups
vgdisplay

# List logical volumes (check stripe count)
lvdisplay -m
```

### Verify Striping

```bash
# Check logical volume details including stripe configuration
lvs -a -o +devices,stripes,stripesize

# Expected output for 4-disk stripe:
# LV   VG         Stripes Stripe KiB  Devices
# vol  hanadata   4       1024        /dev/sdb(0),/dev/sdc(0),/dev/sdd(0),/dev/sde(0)
# vol  hanalog    4       1024        /dev/sdf(0),/dev/sdg(0),/dev/sdh(0),/dev/sdi(0)
```

### Check Mount Options

```bash
# Verify mount options
mount | grep /hana

# Expected output:
# /dev/mapper/hanadata-vol on /hana/data type xfs (rw,relatime,inode64,largeio,swalloc)
# /dev/mapper/hanalog-vol on /hana/log type xfs (rw,relatime,inode64,largeio,swalloc)
# /dev/mapper/hanashared-vol on /hana/shared type xfs (rw,relatime,inode64,largeio,swalloc)
```

### Performance Testing

```bash
# Test sequential write performance on data volume
dd if=/dev/zero of=/hana/data/testfile bs=1M count=10240 oflag=direct

# Test sequential read performance
dd if=/hana/data/testfile of=/dev/null bs=1M iflag=direct

# Clean up
rm /hana/data/testfile
```

## Important Notes

1. **No RAID Controller**: Do not use hardware RAID controllers. Nutanix provides data protection.
2. **No Software RAID**: Do not use mdadm or software RAID. Use LVM striping instead.
3. **Stripe Size**: Always use 1MB (1024 KB) stripe size for SAP HANA workloads.
4. **Full Capacity**: Always use 100% of disk capacity (`-l 100%FREE`).
5. **Separate Volumes**: Never combine /hana/data and /hana/log on the same volume group.
6. **XFS Required**: SAP officially supports only XFS for SAP HANA on SLES and RHEL.
7. **Mount Options**: The mount options `inode64,largeio,swalloc` are critical for performance.

## References

- **SAP Note 1900823**: SAP HANA Storage Requirements
- **SAP Note 2205917**: OS Settings for SLES 12
- **SAP Note 2684254**: OS Settings for SLES 15
- **SAP Note 2686722**: SAP HANA virtualized on Nutanix AOS
- **Red Hat LVM Administration Guide**: https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_logical_volumes/index
- **SUSE LVM Documentation**: https://documentation.suse.com/sles/15-SP5/html/SLES-all/cha-lvm.html

## Troubleshooting

### Issue: LV creation fails with "Insufficient free space"

**Solution**: Check that PVs are properly initialized and not already part of another VG:
```bash
pvs
vgs
# Remove old VG if needed: vgremove <vg_name>
# Remove old PV if needed: pvremove /dev/<disk>
```

### Issue: Mount fails after reboot

**Solution**: Verify /etc/fstab entries and ensure they use device mapper paths:
```bash
cat /etc/fstab | grep hana
# Use /dev/mapper/<vg>-<lv> format, not /dev/<vg>/<lv>
```

### Issue: Poor I/O performance

**Solution**: Verify striping configuration and mount options:
```bash
lvs -o +stripes,stripesize
mount | grep hana
# Ensure inode64,largeio,swalloc are set
```

### Issue: Cannot extend filesystem

**Solution**: LVM allows dynamic extension:
```bash
# Extend logical volume (if VG has free space)
lvextend -l +100%FREE /dev/hanadata/vol

# Resize XFS filesystem
xfs_growfs /hana/data
```

## Automation Example

For automated deployments, consider implementing the LVM configuration steps in your automation framework of choice (Ansible, Terraform provisioners, cloud-init, etc.). Key considerations:

- **Error Handling**: Check return codes at each step (pvcreate, vgcreate, lvcreate)
- **Logging**: Log all operations for audit and troubleshooting purposes
- **Validation**: Verify disk availability before creating PVs
- **Idempotency**: Check if VGs/LVs already exist before creating them
- **Disk Detection**: Automatically detect and exclude the OS disk from data VGs

Example validation approach:
```bash
# Check if VG already exists
if ! vgs | grep -q "hanadata"; then
    vgcreate hanadata /dev/sdb /dev/sdc /dev/sdd /dev/sde
fi

# Check if LV already exists  
if ! lvs | grep -q "hanadata-vol"; then
    lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanadata
fi
```

