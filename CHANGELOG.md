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
- SAP Note 1944799: HANA Guidelines for Nutanix
- SAP Note 2205917: Storage Requirements
- SAP Note 2015553: Linux General Prerequisites
- Extensible SAP notes library structure
- Storage calculation functions
- CPU and memory validation

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
| S    | 128 | 16    | 3          | 2         |
| M    | 256 | 32    | 4          | 3         |
| L    | 512 | 64    | 4          | 3         |
| XL   | 1024| 96    | 6          | 4         |

### Known Limitations

- Scale-out HANA requires manual configuration post-deployment
- High availability (Pacemaker) not automated
- SAP software installation not included (infrastructure only)
- No support for converged systems in production (by SAP recommendation)
- Cloud-init configuration is basic (extend via configuration management)

### Dependencies

- Terraform >= 1.5.0
- Nutanix Provider ~> 1.9.0
- Nutanix AOS 6.x or later
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

