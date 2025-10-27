# LVM Storage Configuration Update Summary

**Date**: October 27, 2025  
**DISCLAIMER**: This is an unofficial document and is NOT supported by SAP SE or Nutanix, Inc.

## Overview

Updated the terraform-sap-nutanix project to reflect the correct storage configuration approach for SAP HANA on Nutanix: **LVM (Logical Volume Manager)** instead of RAID.

## Key Changes

### 1. Storage Strategy

**Before**: References to RAID-0 configurations  
**After**: LVM-based storage with striping for performance

**Rationale**: 
- Nutanix provides data protection (RF2/RF3) at the storage layer
- No need for VM-level RAID
- LVM striping provides performance optimization
- More flexible for future expansion

### 2. New Documentation

Created **LVM_STORAGE_CONFIGURATION.md** with comprehensive coverage:

- Storage architecture principles
- 4 supported disk layout options (3, 9, 12, or single disk)
- Detailed LVM configuration steps
- T-shirt sizing recommendations with LVM layouts
- Storage sizing per SAP Note 1900823
- Terraform implementation guidance
- Cloud-init and automation examples
- Performance verification procedures
- Troubleshooting guide

### 3. Updated SAP Notes Files

#### sap-notes/sap-note-1900823.tf
- **Disk Layout**: Changed from RAID-0 to LVM with proper parameters
  - Added LVM volume manager specifications
  - Changed stripe size from 256KB to 1024KB (1MB) for LVM
  - Added VG names: hanadata, hanalog, hanashared
  - Added lvcreate command examples
  
- **Filesystem Configuration**: Updated XFS mount options
  - Changed from `relatime,inode64,logbufs=8,logbsize=256k,swalloc,nobarrier`
  - To: `inode64,largeio,swalloc` (SAP recommended for Nutanix)
  - Added fstab entry examples with device mapper paths
  
- **Additional Notes**: Added Nutanix-specific LVM configuration
  - Supported disk counts: 3, 9, 12 (excluding OS disk)
  - Detailed layout configurations for each disk count
  - 7-step LVM setup procedure

#### sap-notes/sap-note-2205917.tf
- **Best Practices**: Replaced RAID references with LVM
  - Volume management technology: LVM (not RAID)
  - Stripe size: 1024KB (1MB) for LVM
  - Added lvcreate options with striping parameters
  - Added filesystem specifications (XFS with mount options)
  - Added OS disk separation requirement

### 4. Updated Module Documentation

#### modules/sap-hana/README.md

**Storage Layout Section**:
- Clarified that Terraform provisions disks but LVM must be configured post-deployment
- Added LVM configuration overview with VG names and parameters
- Updated storage examples to show LVM layout:
  - 256GB system: 10 disks (1 OS + 9 data) with 4-way striping
  - 1024GB system: 13 disks (1 OS + 12 data) with 4-way striping
- Added note about Nutanix data protection (no RAID needed)

**Post-Deployment Configuration Section**:
- Split into two parts:
  1. LVM Storage Configuration (always required)
  2. CPU Configuration (required for production)
- Added complete LVM setup example with commands
- Added reference to LVM_STORAGE_CONFIGURATION.md

**Best Practices Section**:
- Added: "Configure LVM storage post-deployment (always required)"
- Added: "Use XFS filesystem with mount options: inode64,largeio,swalloc"
- Added: "Separate OS disk from data disks"

### 5. Technical Specifications

#### LVM Striping Parameters
```bash
Stripe Size:  1MB (-I1M)
Stripe Count: Matches disk count in VG (-i <count>)
Capacity:     100% of VG (-l 100%FREE)
RAID:         none (-r none) - Nutanix handles redundancy
```

#### XFS Mount Options
```
inode64   - Allows inode allocation across entire filesystem (required for >1TB)
largeio   - Optimizes for large I/O operations (SAP HANA pattern)
swalloc   - Stripe width allocation - aligns I/O with LVM stripe geometry
```

#### Volume Group Names
```
hanadata   - /hana/data   (4-way stripe for M/L/XL)
hanalog    - /hana/log    (4-way stripe for M/L/XL)
hanashared - /hana/shared (1-4 disks depending on size)
```

### 6. Disk Layouts by T-Shirt Size

| Size | Memory  | Data Disks | Log Disks | Shared Disks | Total Data Disks | Total Disks    |
|------|---------|------------|-----------|--------------|------------------|----------------|
| XS   | 64 GB   | 2          | 2         | 1            | 5                | 6 (1 OS + 5)   |
| S    | 128 GB  | 2          | 2         | 1            | 5                | 6 (1 OS + 5)   |
| M    | 256 GB  | 4          | 4         | 1            | 9                | 10 (1 OS + 9)  |
| L    | 512 GB  | 4          | 4         | 1            | 9                | 10 (1 OS + 9)  |
| XL   | 1024 GB | 4          | 4         | 4            | 12               | 13 (1 OS + 12) |

### 7. LVM Commands Reference

#### Create Physical Volumes
```bash
pvcreate /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

#### Create Volume Groups
```bash
vgcreate hanadata /dev/sdb /dev/sdc /dev/sdd /dev/sde
```

#### Create Logical Volumes with Striping
```bash
lvcreate -i 4 -I1M -l 100%FREE -r none -n vol hanadata
```

#### Format with XFS
```bash
mkfs.xfs /dev/mapper/hanadata-vol
```

#### fstab Entry
```bash
/dev/mapper/hanadata-vol /hana/data xfs inode64,largeio,swalloc 1 2
```

## Files Modified

1. **NEW**: `LVM_STORAGE_CONFIGURATION.md` - Complete LVM guide
2. **UPDATED**: `sap-notes/sap-note-1900823.tf` - Added LVM specifications
3. **UPDATED**: `sap-notes/sap-note-2205917.tf` - Replaced RAID with LVM
4. **UPDATED**: `modules/sap-hana/README.md` - Updated storage documentation

## Files Removed

None (all changes were updates to existing files or new documentation)

## Migration Notes

### For Existing Deployments

If you have existing VMs provisioned with the old configuration:

1. **Backup Data**: Always backup before making storage changes
2. **Stop SAP HANA**: Shutdown HANA database
3. **Verify Current Layout**: Check existing disk configuration
4. **Plan Migration**: May require VM rebuild depending on current state
5. **Test First**: Validate in non-production environment

### For New Deployments

1. **Terraform Provisions Disks**: Terraform creates VM with attached disks
2. **LVM Configuration Required**: Must configure LVM post-deployment
3. **Use Cloud-Init or Ansible**: Automate LVM setup for consistency
4. **Verify Configuration**: Check striping and mount options

## References

- SAP Note 1900823: SAP HANA Storage Requirements
- SAP Note 2205917: OS Settings for SLES 12
- SAP Note 2684254: OS Settings for SLES 15
- SAP Note 2686722: SAP HANA virtualized on Nutanix AOS
- Red Hat LVM Administration Guide
- SUSE LVM Documentation

## Important Reminders

1. **No RAID**: Do not use hardware or software RAID with Nutanix
2. **Separate OS Disk**: Always keep OS disk separate from HANA data VGs
3. **Stripe Size**: Always use 1MB (1024KB) stripe size for SAP HANA
4. **Full Capacity**: Always use 100% of VG capacity (-l 100%FREE)
5. **XFS Only**: SAP officially supports only XFS for HANA on SLES/RHEL
6. **Mount Options**: Critical to use inode64,largeio,swalloc

## Questions or Issues?

Refer to:
- `LVM_STORAGE_CONFIGURATION.md` for detailed setup
- `modules/sap-hana/README.md` for module-specific guidance
- `sap-notes/README.md` for SAP note implementation details

---

**Note**: This is a community-driven project and not officially endorsed by SAP or Nutanix. Always validate against official vendor documentation.

