# Safety and operational guidance

## PowerShell inventory scripts

- The inventory scripts are read-only with respect to Azure resources: they query metadata and export local CSV reports. They do not create, modify, restart, or delete Azure resources.
- All inventory scripts require an explicit SubscriptionId GUID. This prevents an accidental inventory of whichever subscription happens to be active in the current Az context.
- Pass TenantId when signing in to a specific tenant. Without it, an existing sign-in context is reused, or interactive sign-in is started if no context exists.
- Before querying Azure, the shared helper checks required modules, imports them, selects the requested subscription and verifies that the resulting context matches the requested subscription (and tenant, when supplied). It stops on a mismatch.
- Use a dedicated account with the minimum Azure RBAC permissions needed for the inventory operation. Do not use Owner or Contributor merely for convenience.
- Treat CSV reports as sensitive operational data. Store them securely, restrict access, and remove them according to your organization's retention policy.

## Bicep deployment

- Bicep templates are infrastructure code and can create billable resources. Review every parameter and the deployment preview before applying them. Use az deployment group what-if before deployment.
- The storage account template disables anonymous blob access and Shared Key authorization, requires HTTPS and TLS 1.2, but leaves public network access enabled. Apply private endpoints/firewall rules separately to match your connectivity design.
- Disabling Shared Key can affect legacy applications and tools; validate compatibility before deployment.
- The sample parameter file contains a placeholder name; replace it with a globally unique storage account name before deployment.
- Test in a non-production subscription first. Check policy, region availability, quotas, naming rules, costs, and dependencies.

## General

- Never commit credentials, access tokens, certificates, private keys, tenant data, or generated reports.
- Azure provider APIs and PowerShell modules evolve. Confirm cmdlet and API versions against current Microsoft Learn documentation before production use.
- Automated tests mock Azure cmdlets and do not contact Azure. They are not proof that a live deployment or query will succeed.

These examples are provided as operational starting points, not as a security or compliance certification.
