# PowerShell Instructions

Apply these rules when working with PowerShell files (`.ps1`, `.psm1`, `.psd1`).

## Code Style

- Use 4-space indentation.
- Use `PascalCase` for function names and parameters.
- Use approved PowerShell verbs (`Get-`, `Set-`, `New-`, `Remove-`, etc.).

## Function Structure

Always use `[CmdletBinding()]` for advanced functions. Include comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, and `.EXAMPLE`.

```powershell
<#
.SYNOPSIS
    Brief description of the function
.DESCRIPTION
    Detailed description of what the function does
.PARAMETER ParameterName
    Description of the parameter
.EXAMPLE
    Example usage of the function
#>
function Verb-Noun {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequiredParameter,

        [Parameter(Mandatory = $false)]
        [int]$OptionalParameter = 0
    )

    # Function logic here
}
```

## Error Handling

- Use `try-catch-finally` blocks.
- Report errors with `Write-Error`.
- Set `$ErrorActionPreference` appropriately.
- Validate inputs at the start of functions.

## Security

- Never store credentials in plain text.
- Use secure strings for sensitive data.
- Validate and sanitize all inputs.
- Follow least privilege principles.

## Module Development

- Create proper module manifests (`.psd1`).
- Export only necessary functions.
- Use Public/Private folder structure.
- Follow semantic versioning.

## Testing

- Write Pester tests for all functions.
- Test both positive and negative scenarios.
- Mock external dependencies.

## File Organization

```
PowerShellProject/
├── ModuleName.psd1
├── ModuleName.psm1
├── Public/
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/
│   └── Helper-Function.ps1
├── Tests/
│   ├── ModuleName.Tests.ps1
│   └── Integration.Tests.ps1
├── Docs/
└── Examples/
```

## Environment Compatibility

- Test across PowerShell 5.1 and 7.x.
- Handle differences between Windows PowerShell and PowerShell Core.
- Consider cross-platform compatibility when possible.

## Performance

- Use .NET methods when PowerShell cmdlets are insufficient.
- Avoid unnecessary object creation in loops.
- Use pipeline processing for large datasets.
