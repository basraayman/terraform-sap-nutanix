# Documentation

**DISCLAIMER**: This is a private initiative and is NOT officially supported by SAP SE or Nutanix, Inc.

This directory contains organized documentation for the Terraform SAP on Nutanix project.

## Directory Structure

```
docs/
├── README.md                    # This file
├── updates/                     # Update summaries and change notes
├── operations/                  # Operational guides and procedures
└── architecture/                # Architecture and design documents
```

## Documentation by Category

### Operations Guides

Operational procedures and configuration guides for deployed systems:

- **[LVM Storage Configuration](./operations/LVM_STORAGE_CONFIGURATION.md)**  
  Complete guide for configuring LVM storage for SAP HANA on Nutanix
  
- **[Post-Deployment CPU Configuration](./operations/POST_DEPLOYMENT_CPU_CONFIG.md)**  
  Guide for configuring vNUMA, CPU pinning, and threads per core

### Update Notes

Detailed summaries of updates and changes to the project:

- **[2024-10-27: LVM Storage Configuration](./updates/2024-10-27-lvm-storage-configuration.md)**  
  Major update to use LVM instead of RAID for storage configuration
  
- **[2024-10-26: SAP Notes Corrections](./updates/2024-10-26-sap-notes-corrections.md)**  
  Corrections and updates to SAP note implementations
  
- **[2024-10-26: Storage Sizing Corrections](./updates/2024-10-26-storage-sizing-corrections.md)**  
  Corrections to storage sizing formulas per SAP Note 1900823
  
- **[2024-10-26: Initial Setup](./updates/2024-10-26-initial-setup.md)**  
  Initial project setup and structure

### Architecture Documents

Design decisions and architectural patterns:

- *Coming soon*

## Quick Links

### Main Documentation
- [Main README](../README.md) - Project overview and quick start
- [CHANGELOG](../CHANGELOG.md) - Version history and changes
- [QUICKSTART](../QUICKSTART.md) - Quick start guide
- [CONTRIBUTING](../CONTRIBUTING.md) - Contribution guidelines

### Module Documentation
- [SAP HANA Module](../modules/sap-hana/README.md)
- [SAP NetWeaver Module](../modules/sap-netweaver/README.md)
- [SAP S/4HANA Module](../modules/sap-s4hana/README.md)

### SAP Notes
- [SAP Notes Library](../sap-notes/README.md)

### Examples
- [HANA Single Node](../examples/hana-single-node/README.md)
- [S/4HANA Distributed](../examples/s4hana-distributed/README.md)

## Document Conventions

### Update Notes Format

Update notes follow this structure:
- **Date**: YYYY-MM-DD format in filename
- **Overview**: Brief summary of changes
- **Key Changes**: Detailed list of modifications
- **Files Modified/Added**: Complete list of affected files
- **Migration Notes**: Guidance for existing deployments
- **References**: Related documentation and SAP notes

### Versioning

This project follows [Semantic Versioning](https://semver.org/):
- **Major**: Breaking changes
- **Minor**: New features, backward compatible
- **Patch**: Bug fixes, backward compatible

## Finding Information

### By Topic

| Topic | Location |
|-------|----------|
| Storage configuration | [operations/LVM_STORAGE_CONFIGURATION.md](./operations/LVM_STORAGE_CONFIGURATION.md) |
| CPU configuration | [operations/POST_DEPLOYMENT_CPU_CONFIG.md](./operations/POST_DEPLOYMENT_CPU_CONFIG.md) |
| Version history | [../CHANGELOG.md](../CHANGELOG.md) |
| Update details | [updates/](./updates/) |
| Module usage | [../modules/](../modules/) |
| Examples | [../examples/](../examples/) |

### By Date

Recent updates (newest first):
1. **2024-10-27**: LVM Storage Configuration
2. **2024-10-26**: SAP Notes Corrections
3. **2024-10-26**: Storage Sizing Corrections
4. **2024-10-26**: Initial Project Setup

### By Component

| Component | Documentation |
|-----------|---------------|
| SAP HANA | [modules/sap-hana/README.md](../modules/sap-hana/README.md) |
| SAP NetWeaver | [modules/sap-netweaver/README.md](../modules/sap-netweaver/README.md) |
| SAP S/4HANA | [modules/sap-s4hana/README.md](../modules/sap-s4hana/README.md) |
| Storage | [operations/LVM_STORAGE_CONFIGURATION.md](./operations/LVM_STORAGE_CONFIGURATION.md) |
| CPU/NUMA | [operations/POST_DEPLOYMENT_CPU_CONFIG.md](./operations/POST_DEPLOYMENT_CPU_CONFIG.md) |
| SAP Notes | [../sap-notes/README.md](../sap-notes/README.md) |

## Contributing Documentation

When adding new documentation:

1. **Choose the right location**:
   - Operations guides → `docs/operations/`
   - Update summaries → `docs/updates/` (use YYYY-MM-DD prefix)
   - Architecture docs → `docs/architecture/`

2. **Update this index**: Add links to new documents

3. **Update CHANGELOG**: Record changes in the main changelog

4. **Follow conventions**: Use consistent formatting and structure

5. **Add disclaimers**: Always include the project disclaimer

## Support

For questions or issues:
- Open an issue in the repository
- Check existing documentation first
- Refer to official SAP and Nutanix documentation

## License

See [LICENSE](../LICENSE) for project license information.

---

**Remember**: This is a community project. Always validate configurations against official SAP and Nutanix documentation before production use.

