# Project Instructions

This is an Azure infrastructure project using Terraform, PowerShell, and Azure DevOps Pipelines.

## Core Principles (Priority Order)

1. **KISS** — Start with the simplest solution. Do not add complexity until the simple approach fails.
2. **YAGNI** — Do not add features, abstractions, or configuration until they are actually needed.
3. **SRP** — Each component has one responsibility. Split only when it simplifies understanding.
4. **DRY** — Extract shared logic only after duplication is established and clarity is maintained.

## Working Style

### Assumption Management

Before implementing non-trivial infrastructure changes, explicitly state assumptions:

```
ASSUMPTIONS:
1. [assumption about requirements/constraints]
2. [assumption about existing infrastructure]
→ Correct me now or I'll proceed with these.
```

### Handle Confusion Immediately

When encountering inconsistencies or unclear requirements:

1. STOP - don't guess
2. Name the specific confusion
3. Present the tradeoff or ask the clarifying question
4. Wait for resolution

Example: "I see `westeurope` in variables but `northeurope` in the tfvars. Which is correct?"

### Scope Discipline

Touch only what's requested. Do NOT:

- Remove comments or code you don't fully understand
- "Clean up" unrelated resources as side effects
- Delete unused resources without explicit approval
- Refactor adjacent modules without being asked

### Simplicity Check

Before finishing, ask:

- Can this be simpler?
- Are these abstractions necessary?
- Is this the obvious solution a senior engineer would write?

Prefer boring, obvious solutions over clever ones.

### Change Summary

After modifications, provide:

```
CHANGES MADE:
- [file]: [what and why]

INTENTIONALLY UNCHANGED:
- [file]: [left alone because...]

VERIFICATION NEEDED:
- [any risks or things to double-check]
```

### Push Back When Needed

If an approach has clear problems:

- Point out the issue directly
- Explain the concrete downside
- Propose an alternative
- Accept the decision if overridden

"Of course!" to bad ideas helps no one.

## Security

- Never hardcode secrets, passwords, or API keys. Use environment variables or Azure Key Vault.
- Service Principal credentials must never be committed. Document expected variables, not values.
- Validate all inputs. Follow least privilege for all RBAC and IAM assignments.

## Documentation

- Every project needs a `README.md` with: Purpose, Prerequisites, Setup, Usage, Configuration.
- Store planning documents in `docs/` with timestamp naming: `docs/plan-{yyyy-MM-dd_hh-mm}.md`.

## Language-Specific Instructions

When working on specific file types, reference these as needed:

- Terraform: `.claude/instructions/terraform.md`
- Azure Pipelines: `.claude/instructions/azure-pipelines.md`
- PowerShell: `.claude/instructions/powershell.md`
- Azure CLI / Azure DevOps: `.claude/instructions/azure.md`

**Usage:** `claude "help with this" @.claude/instructions/terraform.md @main.tf`

This approach keeps token usage low by only loading language-specific rules when needed.
