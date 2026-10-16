# CLAUDE.md

Subscription-level foundation (guardrails, per-building-block resource groups
and deploy identities). Ground rules, cost rules and decisions live in the
[ai-intelligence-domain](https://github.com/azure-intelligence-domain/ai-intelligence-domain)
repository.

- Never remove or weaken the budget, the kill switch or their role assignment.
- `rg-intplat-guardrails` is never tagged `costguard=delete`; every other
  resource group is.
- Bicep only. Run `az bicep build` (no warnings) and a what-if before every
  deployment.
- Personal data such as the alert email is passed at deploy time, never
  committed (public repository).
