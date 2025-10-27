# Update Notes

This directory contains detailed update summaries for the Terraform SAP on Nutanix project.

**DISCLAIMER**: This is a private initiative and is NOT officially supported by SAP SE or Nutanix, Inc.

## Overview

Update notes provide comprehensive details about changes, improvements, and corrections made to the project over time. Each update note includes:

- Overview of changes
- Detailed modification lists
- Migration guidance
- Technical specifications
- References to related documentation

## Update History

### 2024-10-27

#### [Documentation Restructure](./2024-10-27-documentation-restructure.md)
**Documentation Update**: Reorganized project documentation for better tracking and navigation.

**Key Changes**:
- Created `docs/` directory structure with operations/, updates/, and architecture/
- Moved operational guides to docs/operations/
- Moved update summaries to docs/updates/ with date prefixes
- Created comprehensive documentation indexes
- Added NAVIGATION.md for quick reference
- Updated all links throughout the project

**Impact**: Documentation only - no code changes. All links updated to new locations.

#### [LVM Storage Configuration](./2024-10-27-lvm-storage-configuration.md)
**Major Update**: Replaced RAID-based storage references with LVM (Logical Volume Manager) configuration.

**Key Changes**:
- Complete LVM storage guide created
- SAP notes updated with LVM specifications
- Module documentation updated for LVM workflows
- Removed all RAID references
- Added XFS mount options per SAP recommendations

**Impact**: All new deployments should use LVM storage configuration. Existing deployments may need migration planning.

---

### 2024-10-26

#### [SAP Notes Corrections](./2024-10-26-sap-notes-corrections.md)
**Update**: Corrected SAP note descriptions and removed incorrect references.

**Key Changes**:
- Updated SAP note descriptions to match official titles
- Removed SAP Note 2015553 (Azure-specific, not applicable)
- Added SAP Note 2686722 (HANA on Nutanix AOS)
- Added SAP Note 1900823 (Storage requirements)
- Documented post-deployment CPU configuration requirements

**Impact**: Documentation now accurately reflects applicable SAP notes for Nutanix deployments.

#### [Storage Sizing Corrections](./2024-10-26-storage-sizing-corrections.md)
**Update**: Corrected storage sizing formulas to match SAP Note 1900823.

**Key Changes**:
- Fixed data volume sizing: 1.5x RAM (was 1.2x)
- Fixed log volume sizing: 0.5x RAM or 512GB min (was 0.6x)
- Updated disk counts for T-shirt sizes
- Corrected shared volume sizing formula
- Added detailed storage calculation examples

**Impact**: VMs will have correct storage sizes per SAP recommendations.

#### [Initial Setup](./2024-10-26-initial-setup.md)
**Initial Release**: Project structure and core modules created.

**Key Components**:
- Terraform modules for SAP HANA, NetWeaver, and S/4HANA
- SAP notes library implementation
- Example configurations
- Comprehensive documentation

**Impact**: Foundation for SAP on Nutanix deployments.

---

## Update Note Format

Each update note follows this structure:

### Header
- **Date**: YYYY-MM-DD
- **Category**: Major/Minor/Patch
- **Disclaimer**: Project status

### Content Sections

1. **Overview**: Brief summary of the update
2. **Key Changes**: Detailed list of modifications
3. **Technical Specifications**: Configuration details
4. **Files Modified**: Complete list of changed files
5. **Migration Notes**: Guidance for existing users
6. **References**: Related documentation and standards

### Example Structure

```markdown
# [Update Title] Summary

**Date**: YYYY-MM-DD
**DISCLAIMER**: [Standard disclaimer]

## Overview
Brief description of what changed and why.

## Key Changes
Detailed list of modifications.

## Files Modified
1. File 1 - Description
2. File 2 - Description

## Migration Notes
Guidance for updating existing deployments.

## References
Links to related documentation.
```

## Finding Updates

### By Date
Files are prefixed with `YYYY-MM-DD` for chronological sorting:
```
2024-10-27-lvm-storage-configuration.md
2024-10-26-sap-notes-corrections.md
2024-10-26-storage-sizing-corrections.md
2024-10-26-initial-setup.md
```

### By Category

| Category | Updates |
|----------|---------|
| Storage | 2024-10-27 (LVM), 2024-10-26 (Sizing) |
| SAP Notes | 2024-10-26 (Corrections) |
| Infrastructure | 2024-10-26 (Initial) |

### By Impact

| Impact Level | Updates |
|--------------|---------|
| High | LVM Storage Configuration (requires action) |
| Medium | Storage Sizing Corrections |
| Low | SAP Notes Corrections (documentation only) |

## Using Update Notes

### For New Deployments
1. Read the latest CHANGELOG for current version
2. Review recent update notes (last 30 days)
3. Follow operational guides in `docs/operations/`

### For Existing Deployments
1. Check update notes since your deployment date
2. Review "Migration Notes" sections for applicable updates
3. Plan and test updates in non-production first

### For Contributors
1. Create update note when making significant changes
2. Use YYYY-MM-DD prefix format
3. Follow the standard structure
4. Update the CHANGELOG
5. Update this README with a summary

## Related Documentation

- **[Main Documentation Index](../README.md)** - Complete documentation overview
- **[CHANGELOG](../../CHANGELOG.md)** - Version history
- **[Operations Guides](../operations/)** - Operational procedures
- **[Module Documentation](../../modules/)** - Module-specific guides

## Changelog Integration

All updates documented here are also recorded in the main [CHANGELOG.md](../../CHANGELOG.md). The CHANGELOG provides version-based tracking while these update notes provide detailed context and migration guidance.

**Update Notes** = Detailed explanations + migration guidance  
**Changelog** = Version tracking + summary of changes

## Questions or Feedback?

For questions about updates:
- Check the update note's "References" section
- Review related operational guides
- Consult module-specific documentation
- Open an issue in the repository

---

**Remember**: Always validate changes against official SAP and Nutanix documentation before production use.

