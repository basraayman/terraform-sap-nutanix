# Quick Navigation Guide

**DISCLAIMER**: This is a private initiative and is NOT officially supported by SAP SE or Nutanix, Inc.

## I want to...

### Get Started
- **Deploy my first SAP HANA VM** → [QUICKSTART.md](./QUICKSTART.md)
- **Understand the project** → [README.md](./README.md)
- **See examples** → [examples/](./examples/)

### Configure Storage
- **Configure LVM for SAP HANA** → [LVM Storage Configuration](./docs/operations/LVM_STORAGE_CONFIGURATION.md)
- **Understand storage sizing** → [SAP Note 1900823](./sap-notes/sap-note-1900823.tf)
- **Troubleshoot storage issues** → [LVM Storage Guide - Troubleshooting](./docs/operations/LVM_STORAGE_CONFIGURATION.md#troubleshooting)

### Configure CPU/NUMA
- **Configure vNUMA and CPU pinning** → [CPU Configuration Guide](./docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md)
- **Understand NUMA requirements** → [SAP Note 2686722](./sap-notes/sap-note-2686722.tf)

### Deploy Specific SAP Systems
- **SAP HANA single-node** → [HANA Module](./modules/sap-hana/README.md)
- **SAP NetWeaver** → [NetWeaver Module](./modules/sap-netweaver/README.md)
- **SAP S/4HANA distributed** → [S/4HANA Module](./modules/sap-s4hana/README.md)

### Understand What Changed
- **See version history** → [CHANGELOG.md](./CHANGELOG.md)
- **Read detailed updates** → [Updates Index](./docs/updates/README.md)
- **Latest changes** → [Update 2024-10-27](./docs/updates/2024-10-27-lvm-storage-configuration.md)

### Find Documentation
- **Browse all documentation** → [Documentation Index](./docs/README.md)
- **Operations guides** → [docs/operations/](./docs/operations/)
- **Update summaries** → [docs/updates/](./docs/updates/)

### Work with SAP Notes
- **See implemented SAP notes** → [SAP Notes Library](./sap-notes/README.md)
- **Understand SAP compliance** → [sap-notes/](./sap-notes/)

### Contribute
- **Learn how to contribute** → [CONTRIBUTING.md](./CONTRIBUTING.md)
- **Understand disclaimers** → [DISCLAIMER.md](./DISCLAIMER.md)
- **See the license** → [LICENSE](./LICENSE)

## By Role

### Infrastructure Administrator
1. [QUICKSTART.md](./QUICKSTART.md) - Deploy systems
2. [LVM Storage Configuration](./docs/operations/LVM_STORAGE_CONFIGURATION.md) - Configure storage
3. [CPU Configuration](./docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md) - Configure CPU settings
4. [Module Documentation](./modules/) - Module-specific details

### SAP Basis Administrator
1. [README.md](./README.md) - Understand the solution
2. [SAP Notes Library](./sap-notes/README.md) - SAP compliance
3. [Examples](./examples/) - Reference implementations
4. [CHANGELOG.md](./CHANGELOG.md) - Track changes

### Developer/Contributor
1. [CONTRIBUTING.md](./CONTRIBUTING.md) - Contribution guidelines
2. [Documentation Index](./docs/README.md) - Full documentation
3. [Project Structure](./README.md#project-structure) - Code organization
4. [CHANGELOG.md](./CHANGELOG.md) - Version history

## By Task

### Initial Deployment
1. Read [QUICKSTART.md](./QUICKSTART.md)
2. Choose your deployment: [examples/](./examples/)
3. Deploy with Terraform
4. Configure LVM: [LVM Storage Configuration](./docs/operations/LVM_STORAGE_CONFIGURATION.md)
5. Configure CPU: [CPU Configuration Guide](./docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md)

### Troubleshooting
- **Storage issues** → [LVM Storage Guide](./docs/operations/LVM_STORAGE_CONFIGURATION.md#troubleshooting)
- **Module errors** → Check module [README.md](./modules/)
- **SAP compliance** → [SAP Notes Library](./sap-notes/README.md)

### Understanding Changes
1. Check [CHANGELOG.md](./CHANGELOG.md) for version summary
2. Read detailed [Update Notes](./docs/updates/README.md)
3. Review affected [Module Documentation](./modules/)

## File Quick Reference

| What | Where |
|------|-------|
| Project overview | [README.md](./README.md) |
| Quick start | [QUICKSTART.md](./QUICKSTART.md) |
| Version history | [CHANGELOG.md](./CHANGELOG.md) |
| LVM storage setup | [docs/operations/LVM_STORAGE_CONFIGURATION.md](./docs/operations/LVM_STORAGE_CONFIGURATION.md) |
| CPU configuration | [docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md](./docs/operations/POST_DEPLOYMENT_CPU_CONFIG.md) |
| All documentation | [docs/README.md](./docs/README.md) |
| Update details | [docs/updates/README.md](./docs/updates/README.md) |
| SAP HANA module | [modules/sap-hana/README.md](./modules/sap-hana/README.md) |
| NetWeaver module | [modules/sap-netweaver/README.md](./modules/sap-netweaver/README.md) |
| S/4HANA module | [modules/sap-s4hana/README.md](./modules/sap-s4hana/README.md) |
| SAP notes library | [sap-notes/README.md](./sap-notes/README.md) |
| HANA example | [examples/hana-single-node/README.md](./examples/hana-single-node/README.md) |
| S/4HANA example | [examples/s4hana-distributed/README.md](./examples/s4hana-distributed/README.md) |
| Contributing | [CONTRIBUTING.md](./CONTRIBUTING.md) |
| Disclaimers | [DISCLAIMER.md](./DISCLAIMER.md) |
| License | [LICENSE](./LICENSE) |

## Directory Structure

```
terraform-sap-nutanix/
├── README.md                 # Start here
├── QUICKSTART.md            # Quick deployment guide
├── CHANGELOG.md             # Version history
├── NAVIGATION.md            # This file
├── docs/                    # Documentation
│   ├── README.md           # Documentation index
│   ├── operations/         # Operational guides
│   │   ├── LVM_STORAGE_CONFIGURATION.md
│   │   └── POST_DEPLOYMENT_CPU_CONFIG.md
│   └── updates/            # Update summaries
│       └── README.md       # Updates index
├── modules/                 # Terraform modules
│   ├── sap-hana/
│   ├── sap-netweaver/
│   └── sap-s4hana/
├── sap-notes/              # SAP notes library
│   └── README.md
└── examples/               # Example deployments
    ├── hana-single-node/
    └── s4hana-distributed/
```

## Tips

- **Start with QUICKSTART.md** for fastest path to deployment
- **Check CHANGELOG.md** for recent changes before deploying
- **Follow operational guides** in docs/operations/ after Terraform deployment
- **Read update notes** in docs/updates/ for detailed change information
- **Validate everything** against official SAP and Nutanix documentation

---

**Remember**: This is a community project. Always validate configurations against official vendor documentation before production use.

