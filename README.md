# Azure-Administration-Toolkit

A collection of PowerShell scripts, Azure CLI examples, Bicep templates, and operational guidance for Microsoft Azure administration.

## Requirements

- PowerShell 7 recommended.
- Azure PowerShell modules: Az.Accounts, Az.Resources, Az.Compute, and/or Az.Network depending on the script.
- An Azure account with read permissions on the selected subscription.
- Azure CLI and Bicep CLI for template validation and deployment.
- Pester 5 to run the test suite.

Install the required module(s) for the script you plan to run:

~~~powershell
Install-Module Az.Accounts -Scope CurrentUser
Install-Module Az.Resources -Scope CurrentUser
Install-Module Az.Compute -Scope CurrentUser
Install-Module Az.Network -Scope CurrentUser
~~~

## Included scripts and templates

| Path | Purpose | Access / impact |
|---|---|---|
| 01-Resource-Inventory/Get-AzureResourceInventory.ps1 | Export resource name, type, resource group, region and resource ID | Read-only |
| 02-Compute/Get-AzureVMInventory.ps1 | Export VM size, OS type, provisioning and power state | Read-only |
| 03-Networking/Get-AzureNetworkSecurityGroupInventory.ps1 | Export custom NSG security rules | Read-only |
| 04-Storage/main.bicep | Deploy a StorageV2 account with secure baseline settings | Creates a billable Azure resource |

## Azure context safety

All three inventory scripts require an explicit SubscriptionId GUID. They verify that the selected Azure context matches that subscription before querying resources. You can also pass TenantId when you need to sign in to a specific tenant.

Example:

~~~powershell
./01-Resource-Inventory/Get-AzureResourceInventory.ps1 -SubscriptionId "<subscription-guid>" -TenantId "<tenant-guid>"
~~~

If TenantId is omitted, the script uses the current Azure sign-in context, or starts interactive sign-in if no context exists. The script then selects the requested subscription and stops if the resulting context does not match. Inspect the current context with Get-AzContext.

Reports are written to the local Reports/ directory with timestamped filenames. Treat CSV reports as sensitive operational data.

## Bicep storage account example

The template requires a globally unique storage account name. Replace the placeholder in 04-Storage/main.bicepparam before deployment.

Validate and preview before creating anything:

~~~bash
az bicep build --file 04-Storage/main.bicep
az deployment group what-if --resource-group "<resource-group>" --template-file 04-Storage/main.bicep --parameters 04-Storage/main.bicepparam
~~~

Deploy only after reviewing the what-if output and confirming cost, region, naming, policy and network requirements:

~~~bash
az deployment group create --resource-group "<resource-group>" --template-file 04-Storage/main.bicep --parameters 04-Storage/main.bicepparam
~~~

The template enforces HTTPS, TLS 1.2, disables anonymous blob access and disables Shared Key authorization. Public network access remains enabled; configure private endpoints or network restrictions separately to suit your architecture. Disabling Shared Key can affect legacy applications and tools, so validate compatibility before deployment.

## Tests

Run the Pester 5 suite from the repository root:

~~~powershell
Install-Module Pester -RequiredVersion 5.7.1 -Scope CurrentUser -Force
Invoke-Pester -Path ./tests -Output Detailed
~~~

A GitHub Actions workflow runs the same tests on pushes and pull requests. These tests cover PowerShell parsing and mocked context-selection behavior; they do not replace integration testing against a non-production Azure subscription.

## Safety

Read-only scripts still access subscription metadata. Protect generated reports. Bicep deployments can incur charges and change your environment; always run what-if, review the template, and test in a non-production subscription first. See docs/SAFETY.md.

## Validation status

The repository has not yet been validated against a live Azure subscription. The PowerShell parser and Pester 5.7.1 suite pass in GitHub Actions. Live Azure cmdlet behavior, permissions, policy and query outputs have not been integration-tested; validate these in a non-production subscription before production use.

## License

No license has been selected. Unless a license is added, standard copyright applies and reuse/redistribution permissions are not granted.
