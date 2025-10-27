# Contributing to Terraform SAP on Nutanix

Thank you for your interest in contributing to this project! This guide will help you get started.

## Important Notice

**DISCLAIMER**: This is a private, community-driven initiative and is NOT officially supported by SAP SE or Nutanix, Inc. Contributions are made by the community for the community. Always validate against official vendor documentation.

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How to Contribute](#how-to-contribute)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Adding New Features](#adding-new-features)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

This project adheres to professional standards. Please:
- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Maintain a professional tone

## How to Contribute

### Reporting Issues

Before creating an issue:
1. Search existing issues to avoid duplicates
2. Collect relevant information (Terraform version, Nutanix version, etc.)
3. Create a minimal reproducible example if possible

Create an issue for:
- Bugs or errors
- Feature requests
- Documentation improvements
- Questions (use discussions for general questions)

### Suggesting Enhancements

Enhancement suggestions are welcome! Please provide:
- Clear use case description
- Expected vs. current behavior
- Any relevant SAP notes or best practices
- Example configuration (if applicable)

## Development Setup

### Prerequisites

- Terraform >= 1.5.0
- Access to a Nutanix cluster (for testing) or potentially Community Edition
- Git
- Text editor/IDE with HCL support

### Setup

```bash
# Clone repository
git clone https://github.com/basraayman/terraform-sap-nutanix.git
cd terraform-sap-nutanix

# Create a branch for your work
git checkout -b feature/your-feature-name
```

## Project Structure

```
terraform-sap-nutanix/
├── modules/              # Reusable modules
│   ├── sap-hana/        # HANA database module
│   ├── sap-netweaver/   # NetWeaver module
│   └── sap-s4hana/      # S/4HANA orchestration module
├── sap-notes/           # SAP note implementations
├── examples/            # Usage examples
├── README.md            # Main documentation
└── versions.tf          # Provider versions
```

## Adding New Features

### Adding a New Module

1. Create module directory: `modules/your-module-name/`
2. Required files:
   - `main.tf` - Main resources
   - `variables.tf` - Input variables
   - `outputs.tf` - Output values
   - `README.md` - Module documentation

3. Follow existing module structure:
   ```hcl
   # modules/your-module/main.tf
   terraform {
     required_providers {
       nutanix = {
         source  = "nutanix/nutanix"
         version = "~> 1.9.0"
       }
     }
   }
   
   # Your module code...
   ```

4. Document all variables and outputs
5. Include usage examples in README
6. Add SAP note references where applicable

### Adding SAP Note Implementation

1. Create file: `sap-notes/sap-note-XXXXXX.tf`
2. Structure:
   ```hcl
   # ============================================================================
   # SAP Note XXXXXX - Title
   # ============================================================================
   #
   # Link: https://launchpad.support.sap.com/#/notes/XXXXXX
   # ============================================================================
   
   locals {
     sap_note_XXXXXX = {
       note_number = "XXXXXX"
       title       = "Note Title"
       
       # Configuration values
       # ...
     }
   }
   ```

3. Document in `sap-notes/README.md`
4. Reference in relevant modules

### Adding Examples

1. Create directory: `examples/your-example-name/`
2. Required files:
   - `main.tf` - Example configuration
   - `variables.tf` - Variables
   - `terraform.tfvars.example` - Example values
   - `README.md` - Example documentation

3. Follow template pattern from existing examples
4. Include architecture diagrams (ASCII or image)
5. Document prerequisites and steps

## Testing

### Manual Testing

1. Set up test environment:
   ```bash
   cd examples/your-example
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with test values
   ```

2. Test deployment:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Verify:
   - All resources created successfully
   - Outputs are correct
   - SAP notes compliance
   - No errors in logs

4. Clean up:
   ```bash
   terraform destroy
   ```

### Validation Checklist

Use this checklist before submitting:

- [ ] terraform fmt applied
- [ ] terraform validate passes
- [ ] No hardcoded credentials
- [ ] Variables have descriptions
- [ ] Variables have appropriate types
- [ ] Variables have validation where appropriate
- [ ] Outputs are documented
- [ ] README is updated
- [ ] Examples work
- [ ] SAP note references are accurate

## Documentation

### Code Documentation

- Use clear, descriptive variable names
- Add comments for complex logic
- Include SAP note references in comments
- Document assumptions and limitations

Example:
```hcl
# Calculate data disk size per SAP Note 2205917
# Minimum requirement: 1x RAM for HANA data volume
local {
  data_disk_size_gb = max(
    var.data_disk_size_gb,
    var.memory_gb * 1.0  # 1x RAM minimum
  )
}
```

### README Documentation

Each module and example should have README with:
- Overview and purpose
- Features list
- SAP notes implemented
- Usage examples
- Variables table
- Outputs table
- Requirements
- References

Use tables for variables:
```markdown
| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| vm_name | string | - | Name of the VM |
```

### Changelog

Update CHANGELOG.md with:
- Version number (if applicable)
- Date
- Added features
- Changed behavior
- Fixed bugs
- Deprecated features

## Pull Request Process

### Before Submitting

1. Test your changes thoroughly
2. Update documentation
3. Run formatting: `terraform fmt -recursive`
4. Validate: `terraform validate`
5. Update CHANGELOG.md
6. Commit with clear messages

### Commit Messages

Follow conventional commits format:
```
type(scope): subject

body

footer
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Testing changes
- `chore`: Maintenance tasks

Examples:
```
feat(sap-hana): add support for custom disk layouts

Added ability to specify custom disk configurations for
non-standard HANA deployments. Includes validation per
SAP Note 2205917.

Closes #123
```

```
fix(sap-netweaver): correct instance number validation

Instance numbers now properly validated to allow 00-99 range.

Fixes #456
```

### Pull Request Template

When creating PR, include:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring

## SAP Notes
List any SAP notes affected or implemented

## Testing
Describe testing performed

## Checklist
- [ ] Code follows project style
- [ ] Documentation updated
- [ ] Examples updated (if needed)
- [ ] terraform fmt applied
- [ ] terraform validate passes
- [ ] Tested manually
- [ ] CHANGELOG updated
```

### Review Process

1. Submit pull request
2. Automated checks run
3. Code review by maintainers
4. Address feedback
5. Approval and merge

## Style Guide

### Terraform

- Use 2 spaces for indentation
- Run `terraform fmt` before committing
- Use meaningful resource names
- Group related resources with comments
- Use locals for calculated values
- Validate inputs where appropriate

### Variable Naming

- Use descriptive names: `hana_instance_number` not `num`
- Use underscores: `vm_name` not `vmName`
- Boolean: Start with `enable_` or `is_`
- Counts: Start with `num_` or end with `_count`

### File Organization

- Keep related resources together
- Use comments to section code
- Put data sources at top
- Put resources in logical order
- Put outputs at end

## Resources

- [Terraform Style Guide](https://www.terraform.io/docs/language/syntax/style.html)
- [Nutanix Provider Documentation](https://registry.terraform.io/providers/nutanix/nutanix/latest/docs)
- [SAP Notes](https://launchpad.support.sap.com)
- [Nutanix SAP Documentation](https://portal.nutanix.com/page/documents/list?type=software&filterKey=software&filterVal=SAP)

## Questions?

- Check existing documentation
- Search existing issues
- Create a new discussion
- Contact maintainers

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to this community project!

