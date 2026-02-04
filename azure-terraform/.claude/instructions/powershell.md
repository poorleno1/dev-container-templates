# PowerShell — Project Standards

## Function Requirements
- `[CmdletBinding()]` for all functions
- Comment-based help: `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
- Approved verbs: `Get-`, `Set-`, `New-`, `Remove-`

## Security
- Never plain text credentials
- Use secure strings for sensitive data
- Validate all inputs

## Module Structure (if applicable)
```
ModuleName.psd1, ModuleName.psm1
Public/, Private/, Tests/
```

## Compatibility
Test on PowerShell 5.1 and 7.x when possible
