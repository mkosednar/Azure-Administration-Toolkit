# Quick start

## Azure PowerShell inventory

1. Open PowerShell 7.
2. Install the module required by the selected script (see the repository README).
3. Run `Get-AzContext` to inspect the current account, tenant and subscription.
4. Run the desired inventory script. Pass `-SubscriptionId` to select a subscription explicitly.
5. Review the generated CSV in `Reports/` and treat it as sensitive operational data.

## Bicep template

1. Install Azure CLI and Bicep.
2. Replace the sample storage account name in `04-Storage/main.bicepparam` with a globally unique name.
3. Sign in with `az login` and select the intended subscription using `az account set --subscription "<subscription-guid>"`.
4. Validate the template with `az bicep build --file 04-Storage/main.bicep`.
5. Preview changes using `az deployment group what-if`.
6. Deploy only after reviewing the preview, permissions, cost and network design.

Do not use production subscriptions for first-time testing. See [SAFETY.md](SAFETY.md).
