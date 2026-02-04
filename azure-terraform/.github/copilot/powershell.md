# PowerShell Instructions

When working with PowerShell files (.ps1, .psm1, .psd1), follow these specific guidelines:

## Code Style and Formatting
- Use 4 spaces for indentation (configured in .editorconfig)
- Follow PowerShell best practices from the PowerShell Style Guide
- Use PascalCase for function names and parameters
- Use approved PowerShell verbs (Get-, Set-, New-, Remove-, etc.)

## Function Structure
- Always include comment-based help for functions
- Use [CmdletBinding()] for advanced functions
- Define parameters with types and validation
- Include examples in help documentation

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
.NOTES
    Additional information about the function
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
- Use try-catch-finally blocks for error handling
- Implement proper error reporting with Write-Error
- Use $ErrorActionPreference appropriately
- Validate inputs at the beginning of functions

## Security Best Practices
- Never store credentials in plain text
- Use secure strings for sensitive data
- Implement proper credential management
- Validate and sanitize all inputs
- Use least privilege principles

## Module Development
- Create proper module manifests (.psd1)
- Export only necessary functions
- Include module help and examples
- Follow semantic versioning

## PowerShell Specific Features
- Use PowerShell-native cmdlets when available
- Leverage the pipeline effectively
- Use proper parameter sets for different function behaviors
- Implement whatif and confirm parameters where appropriate

## Testing
- Write Pester tests for all functions
- Test both positive and negative scenarios
- Mock external dependencies
- Aim for good code coverage

## Documentation
- Include synopsis, description, parameters, and examples
- Use comment-based help format
- Document any prerequisites or dependencies
- Include version history in module manifests

## Performance
- Use .NET methods when PowerShell cmdlets are insufficient
- Avoid unnecessary object creation in loops
- Use pipeline processing for large datasets
- Consider using background jobs for long-running tasks

## File Organization
```
PowerShellProject/
├── ModuleName.psd1         # Module manifest
├── ModuleName.psm1         # Module file
├── Public/                 # Public functions
│   ├── Get-Something.ps1
│   └── Set-Something.ps1
├── Private/                # Private/internal functions
│   └── Helper-Function.ps1
├── Tests/                  # Pester tests
│   ├── ModuleName.Tests.ps1
│   └── Integration.Tests.ps1
├── Docs/                   # Documentation
└── Examples/               # Usage examples
```

## Environment Compatibility
- Test across different PowerShell versions (5.1, 7.x)
- Consider cross-platform compatibility when possible
- Handle differences between Windows PowerShell and PowerShell Core
- Use appropriate compatibility attributes when needed