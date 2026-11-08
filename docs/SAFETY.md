# Safety and operational guidance

- These PowerShell inventory scripts are read-only: they query Azure resources and export local CSV reports. They do not create, modify, restart, or delete Azure resources.
- Verify the active tenant and subscription with `Get-AzContext` before running any command. Use the optional `-SubscriptionId` parameter to select a known subscription.
- Use a dedicated account with the minimum Azure RBAC permissions needed for the inventory operation. Do not use Owner or Contributor merely for convenience.
- Treat CSV reports as sensitive operational data. Store them securely, restrict access, and remove them according to your organization's retention policy.
- Bicep templates are infrastructure code and can create billable resources. Review every parameter and the deployment preview before applying them. Use `az deployment group what-if` before deployment.
- The storage account template disables anonymous blob access and Shared Key authorization, requires HTTPS and TLS 1.2, but leaves public network access enabled. Apply private endpoints/firewall rules separately to match your connectivity design.
- The sample parameter file contains a placeholder name; replace it with a globally unique storage account name before deployment.
- Test in a non-production subscription first. Check policy, region availability, quotas, naming rules, costs, and dependencies.
- Never commit credentials, access tokens, certificates, private keys, tenant data, or generated reports.
- Azure provider APIs and PowerShell modules evolve. Confirm cmdlet and API versions against current Microsoft Learn documentation before production use.

These examples are provided as operational starting points, not as a security or compliance certification.
