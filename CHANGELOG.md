# Changelog

All notable changes to the Terraform SAP on Nutanix project will be documented in this file.

**DISCLAIMER**: This is a private initiative and is NOT officially supported by SAP SE or Nutanix, Inc.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-10-26

### Added

#### Core Infrastructure
- Initial release of Terraform modules for SAP on Nutanix
- Support for Nutanix Terraform Provider v1.9.x
- Root module with provider configuration and common data sources
- Comprehensive variable validation across all modules

#### SAP HANA Module
- SAP HANA single-node deployment support
- T-shirt sizing presets (XS, S, M, L, XL)
- Custom sizing support for non-standard configurations
- Automatic storage layout per SAP Note 2205917
- NUMA optimization for large memory systems (>256 GB)
- Cloud-init integration for guest customization
- Backup disk provisioning
- Multi-network interface support
- Ansible inventory generation

#### SAP NetWeaver Module
- Support for all NetWeaver instance types (PAS, AAS, ASCS, ERS, WDP)
- ABAP, Java, and Dual-stack configurations
- Flexible sizing per instance type
- Dedicated storage for /usr/sap and /sapmnt
- Instance number validation
- Cloud-init integration

#### SAP S/4HANA Module
- Complete S/4HANA landscape orchestration
- Distributed architecture support
- Converged deployment option (DB + App on same VM)
- High availability support (ASCS/ERS)
- Automatic Ansible inventory generation
- Scale-out application server support
- Web Dispatcher integration
- Comprehensive output variables

#### SAP Notes Implementation
- SAP Note 1944799: SLES OS Installation Guidelines
- SAP Note 1900823: Storage Connector API (1.5x RAM data, 0.5x RAM log)
- SAP Note 2686722: HANA virtualized on Nutanix AOS
- SAP Note 2205917: OS Settings for SLES 12
- SAP Note 2684254: OS Settings for SLES 15
- SAP Note 2772999: RHEL 8.x Installation and Configuration
- SAP Note 3108316: RHEL 9.x Installation and Configuration
- Extensible SAP notes library structure
- Storage calculation functions per official formulas
- CPU and memory validation
- Post-deployment CPU configuration documentation (vNUMA, pinning, threads)

#### Examples
- HANA single-node example with full documentation
- S/4HANA distributed system example
- Complete terraform.tfvars.example files
- Architecture diagrams (ASCII art)
- Step-by-step deployment guides
- Troubleshooting sections

#### Documentation
- Comprehensive README with quick start guide
- Module-specific documentation
- SAP notes implementation guide
- Contributing guidelines
- Project structure documentation
- Best practices and recommendations

### Features

- **Modularity**: Reusable, composable modules for different SAP scenarios
- **Extensibility**: Easy to add new SAP notes and configurations
- **Validation**: Built-in validation for SAP requirements
- **Automation**: Ansible inventory generation
- **Flexibility**: Support for both preset and custom sizing
- **Compliance**: Built-in SAP note compliance
- **Documentation**: Extensive inline and external documentation

### Technical Specifications

#### Supported Configurations
- SAP HANA: 64 GB to 12 TB memory
- SAP NetWeaver: All instance types
- SAP S/4HANA: Converged and distributed
- Operating Systems: SLES 15 SP4+, RHEL 8.4+
- Nutanix: AHV on AOS 6.x+

#### Storage
- XFS filesystem (recommended)
- Automatic sizing based on RAM
- Multi-disk striping for performance
- Separate volumes for data/log/shared/backup

#### Network
- Single or multi-network interface support
- Static IP or DHCP
- VLAN support via Nutanix subnets

#### Sizing Presets
| Size | RAM | vCPUs | Data Disks | Log Disks |
|------|-----|-------|------------|-----------|
| XS   | 64  | 8     | 2          | 2         |
| S    | 128 | 16    | 2          | 2         |
| M    | 256 | 32    | 4          | 4         |
| L    | 512 | 64    | 4          | 4         |
| XL   | 1024| 96    | 4          | 4         |

### Known Limitations

- Scale-out HANA requires manual configuration post-deployment
- High availability (Pacemaker) not automated
- SAP software installation not included (infrastructure only)
- No support for converged systems in production (by SAP recommendation)
- Cloud-init configuration is basic (extend via configuration management)

### Dependencies

- Terraform >= 1.5.0
- Nutanix Provider ~> 1.9.0
- Nutanix AOS 6.5 or later
- Prism Central or Prism Element

### Breaking Changes

None (initial release)

### Deprecated

None (initial release)

### Security

- All credential variables marked as sensitive
- No credentials in version control
- .gitignore configured for secrets
- SSH key support via cloud-init

### Contributors

Initial development and documentation.

---

## [1.1.0] - 2024-10-27

### Changed

#### Storage Architecture
- **BREAKING**: Replaced RAID-based storage configuration with LVM (Logical Volume Manager)
- Updated all storage documentation to reflect LVM-based approach
- Changed XFS mount options from `relatime,inode64,logbufs=8,logbsize=256k,swalloc,nobarrier` to `inode64,largeio,swalloc`
- Updated stripe size from 256KB to 1MB (1024KB) for LVM striping

#### SAP Notes Updates
- Updated SAP Note 1900823 implementation with LVM specifications
- Added volume group names: `hanadata`, `hanalog`, `hanashared`
- Updated SAP Note 2205917 with LVM best practices
- Added detailed LVM configuration steps and examples

#### Documentation Structure
- Created `docs/` directory for organized documentation
- Moved operational guides to `docs/operations/`
- Moved update summaries to `docs/updates/`
- Added documentation index at `docs/README.md`
- Added update notes index at `docs/updates/README.md`

### Added

#### Operations Guides
- **[LVM Storage Configuration Guide](./docs/operations/LVM_STORAGE_CONFIGURATION.md)** - Comprehensive 395-line guide covering:
  - Storage architecture without RAID (Nutanix provides data protection)
  - 4 disk layout options (3, 9, 12, or single disk configurations)
  - Complete LVM setup procedures with commands
  - T-shirt sizing with LVM layouts
  - Performance verification and troubleshooting
  - Cloud-init automation examples

#### Update Notes
- [2024-10-27: LVM Storage Configuration](./docs/updates/2024-10-27-lvm-storage-configuration.md)
- [2024-10-26: SAP Notes Corrections](./docs/updates/2024-10-26-sap-notes-corrections.md)
- [2024-10-26: Storage Sizing Corrections](./docs/updates/2024-10-26-storage-sizing-corrections.md)
- [2024-10-26: Initial Setup](./docs/updates/2024-10-26-initial-setup.md)

#### Documentation
- Added comprehensive documentation structure
- Added navigation and indexing for all docs
- Added cross-references between documents

### Fixed

- Corrected storage configuration approach for Nutanix platform
- Removed RAID references that don't apply to Nutanix (data protection at storage layer)
- Updated mount options to match SAP recommendations for virtualized environments
- Fixed file paths and references throughout documentation

### Technical Details

#### LVM Configuration Parameters
```bash
Stripe Size:  1MB (-I1M)
Stripe Count: Matches disk count in VG (-i <count>)
Capacity:     100% of VG (-l 100%FREE)
RAID:         none (-r none) - Nutanix handles redundancy
```

#### XFS Mount Options
```
inode64   - Allows inode allocation across entire filesystem (required for >1TB)
largeio   - Optimizes for large I/O operations (SAP HANA large sequential I/O)
swalloc   - Stripe width allocation - aligns I/O with LVM stripe geometry
```

#### Volume Group Structure
- `hanadata` → /hana/data (4-way stripe for M/L/XL sizes)
- `hanalog` → /hana/log (4-way stripe for M/L/XL sizes)
- `hanashared` → /hana/shared (1-4 disks depending on size)

### Migration Notes

For existing deployments using the old storage configuration:
1. **New Deployments**: Follow the new LVM configuration guide
2. **Existing Deployments**: Evaluate migration needs - may require VM rebuild
3. **Documentation**: All storage references updated to LVM-based approach
4. **No Downtime Path**: LVM can be configured on existing VMs if disks not yet formatted

See [LVM Storage Configuration](./docs/operations/LVM_STORAGE_CONFIGURATION.md) for complete details.

---

## [Unreleased]

### Planned

- Scale-out HANA master/worker configuration
- HANA System Replication (HSR) support
- Pacemaker cluster automation for HA
- Additional SAP note implementations
- Disaster recovery scenarios
- Monitoring integration templates
- Backup automation examples
- Performance tuning profiles
- Cost estimation module
- Support for additional OS versions
- Network Load Balancer integration
- Multi-cluster deployment support
- Ansible playbooks for LVM configuration automation

---

## Release Notes Format

### Added
New features and capabilities

### Changed
Changes in existing functionality

### Deprecated
Soon-to-be removed features

### Removed
Removed features

### Fixed
Bug fixes

### Security
Security-related changes

---

For more information, see:
- [README.md](./README.md)
- [Contributing Guide](./CONTRIBUTING.md)
- [Examples](./examples/)

