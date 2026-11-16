# Quick start

## Azure PowerShell inventory

1. Open PowerShell 7.
2. Install the module required by the selected script (see the repository README).
3. Identify the intended subscription and tenant IDs in the Azure portal or with Azure CLI.
4. Run the desired inventory script and pass the explicit SubscriptionId. Pass TenantId when signing in to a specific tenant.
5. The script selects and verifies the requested context before querying Azure. If the context cannot be matched, it stops without collecting inventory.
6. Review the generated CSV in Reports/ and treat it as sensitive operational data.

Example:

~~~powershell
./01-Resource-Inventory/Get-AzureResourceInventory.ps1 -SubscriptionId "<subscription-guid>" -TenantId "<tenant-guid>"
~~~

## Bicep template

1. Install Azure CLI and Bicep.
2. Replace the sample storage account name in 04-Storage/main.bicepparam with a globally unique name.
3. Sign in with az login and select the intended subscription using az account set --subscription "<subscription-guid>".
4. Validate the template with az bicep build --file 04-Storage/main.bicep.
5. Preview changes using az deployment group what-if.
6. Deploy only after reviewing the preview, permissions, cost and network design.

Do not use production subscriptions for first-time testing. See SAFETY.md.
