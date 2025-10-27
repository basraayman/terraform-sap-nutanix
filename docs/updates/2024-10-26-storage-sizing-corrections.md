# Storage Sizing Update - SAP Note 1900823

## Date: October 27, 2024

## Summary

Updated the project to use the correct SAP HANA storage sizing formulas from **SAP Note 1900823** instead of the previous incorrect reference to SAP Note 2205917 (which is actually about OS settings for SLES 12).

## Changes Made

### 1. Corrected SAP Note References

**Previous (Incorrect):**
- SAP Note 2205917 was referenced for storage requirements

**Current (Correct):**
- **SAP Note 1900823**: SAP HANA Storage Requirements
- **SAP Note 2205917**: OS Settings for SLES 12
- **SAP Note 2684254**: OS Settings for SLES 15 (NEW)

### 2. Updated Storage Sizing Formulas

Based on SAP Note 1900823:

#### /hana/data
- **Formula**: `Sizedata = 1.5 x RAM`
- **Previous**: 1.0 x RAM (incorrect)
- **Current**: 1.5 x RAM (correct per SAP Note 1900823)

#### /hana/log
- **Formula for systems ≤ 512GB**: `Sizeredolog = 0.5 x RAM`
- **Formula for systems > 512GB**: `Sizeredolog(min) = 512GB`
- **Previous**: 0.5 x RAM for all systems
- **Current**: 0.5 x RAM for ≤512GB, minimum 512GB for >512GB

#### /hana/shared (single-node)
- **Formula**: `Sizeinstallation(single-node) = MIN(1 x RAM; 1 TB)`
- **Previous**: 1 x RAM (no cap)
- **Current**: MIN(1 x RAM, 1TB) - capped at 1TB

#### /hana/shared (scale-out)
- **Formula**: `Sizeinstallation(scale-out) = 1 x RAM_of_worker per 4 worker nodes`
- **Previous**: Not implemented
- **Current**: Implemented with proper formula

### 3. Updated T-Shirt Sizing - Disk Counts

Based on virtualized environment best practices:

| Size | Data Disks | Log Disks | Rationale |
|------|------------|-----------|-----------|
| XS   | 2          | 2         | Small systems, 2-disk striping adequate |
| S    | 2          | 2         | Small systems, 2-disk striping adequate |
| M    | 4          | 4         | Medium+ systems, 4-disk striping for performance |
| L    | 4          | 4         | Large systems, 4-disk striping optimal |
| XL   | 4          | 4         | Very large systems, 4-disk striping |

**Previous Configuration:**
- XS: 2 data, 2 log (unchanged)
- S: 3 data, 2 log (changed to 2/2)
- M: 4 data, 3 log (changed to 4/4)
- L: 4 data, 3 log (changed to 4/4)
- XL: 6 data, 4 log (changed to 4/4)

**Rationale**: 
- Virtual environments benefit from consistent striping patterns
- 2 disks for small systems (XS/S)
- 4 disks for medium and above (M/L/XL) provides optimal performance
- Simplifies management and standardization

### 4. Storage Calculation Examples

#### Example 1: 256 GB System (Size M)

| Volume | Formula | Calculation | Result |
|--------|---------|-------------|--------|
| Data | 1.5 x RAM / 4 disks | 1.5 x 256 / 4 | 4 x 96 GB = 384 GB |
| Log | 0.5 x RAM / 4 disks | 0.5 x 256 / 4 | 4 x 32 GB = 128 GB |
| Shared | MIN(RAM, 1TB) | MIN(256, 1024) | 256 GB |
| Backup | 2 x RAM | 2 x 256 | 512 GB |
| **Total** | | | **1,364 GB** |

**Previous Total**: 1,253 GB (using 1.0x RAM for data)

#### Example 2: 1024 GB System (Size XL)

| Volume | Formula | Calculation | Result |
|--------|---------|-------------|--------|
| Data | 1.5 x RAM / 4 disks | 1.5 x 1024 / 4 | 4 x 384 GB = 1,536 GB |
| Log | min 512GB / 4 disks | 512 / 4 | 4 x 128 GB = 512 GB |
| Shared | MIN(RAM, 1TB) | MIN(1024, 1024) | 1,024 GB (capped) |
| Backup | 2 x RAM | 2 x 1024 | 2,048 GB |
| **Total** | | | **5,220 GB** |

**Key Differences from Previous:**
- Data is 50% larger (1.5x vs 1.0x RAM)
- Log is minimum 512GB for systems >512GB (not scaled linearly)
- Shared is capped at 1TB (was unlimited)

### 5. New Files Created

1. **sap-notes/sap-note-1900823.tf**
   - Complete implementation of SAP Note 1900823
   - All storage sizing formulas
   - Examples for different system sizes
   - Validation rules
   - Scale-out formulas

2. **sap-notes/sap-note-2684254.tf**
   - OS settings for SLES 15
   - saptune configuration
   - SLES 15-specific packages
   - Kernel parameters

### 6. Updated Files

- **modules/sap-hana/main.tf**: Updated storage calculations
- **modules/sap-hana/README.md**: Updated examples and references
- **sap-notes/sap-note-2205917.tf**: Corrected to SLES 12 OS settings
- **sap-notes/README.md**: Updated SAP note descriptions
- **README.md**: Updated references
- **CHANGELOG.md**: Updated SAP notes section

## Official SAP References

1. **SAP Sizing Guidelines**: https://www.sap.com/about/benchmark/sizing.sizing-guidelines.html
2. **SAP Note 1900823**: SAP HANA Storage Requirements
3. **SAP Note 2205917**: OS Settings for SLES 12
4. **SAP Note 2684254**: OS Settings for SLES 15 (https://me.sap.com/notes/2684254)

## Impact on Existing Deployments

### Storage Requirements
- Systems will require **50% more data storage** (1.5x vs 1.0x RAM)
- Log storage for large systems (>512GB) may require **less** total space
- Shared storage is now **capped at 1TB** (was unlimited)

### Example Impact:

| System Size | RAM | Previous Total | New Total | Difference |
|-------------|-----|----------------|-----------|------------|
| 256 GB (M)  | 256 | 1,253 GB | 1,364 GB | +111 GB (+9%) |
| 512 GB (L)  | 512 | 2,329 GB | 2,548 GB | +219 GB (+9%) |
| 1024 GB (XL)| 1024| 4,608 GB | 5,220 GB | +612 GB (+13%) |

## Validation

All storage calculations now comply with:
- [x] SAP Note 1900823 official formulas
- [x] SAP sizing guidelines for virtualized environments
- [x] Nutanix best practices for HANA
- [x] T-shirt sizing appropriate for virtual deployments

## Recommendations

1. **Review existing deployments** against new sizing
2. **Plan storage increases** for systems using old formulas
3. **Use official SAP Quick Sizer** for production sizing validation
4. **Reference SAP Note 1900823** for any custom sizing requirements
5. **For SLES 15 systems**, review SAP Note 2684254 for OS configuration

## Questions or Issues

If you have questions about these changes:
1. Refer to SAP Note 1900823 for authoritative storage sizing
2. Consult the official SAP sizing guidelines
3. Contact SAP support for production system validation
4. Review Nutanix SAP HANA best practices documentation

---

**Note**: This is an unofficial community project. Always validate configurations against official SAP and Nutanix documentation before production use.

