# Azure-Administration-Toolkit

A collection of PowerShell scripts, Azure CLI examples, Bicep templates, and operational guidance for Microsoft Azure administration.

## Repository status

The current PowerShell examples are read-only inventory reports. The Bicep example is deployable infrastructure code and can create a billable resource. Planned topics are listed separately below.

## Requirements

- PowerShell 7 recommended.
- Azure PowerShell modules: Az.Accounts, Az.Resources, Az.Compute, and/or Az.Network depending on the script.
- An Azure account with read permissions on the selected subscription.
- Azure CLI and Bicep CLI for template validation and deployment.

Install modules as needed:

```powershell
Install-Module Az.Accounts -Scope CurrentUser
Install-Module Az.Resources -Scope CurrentUser
Install-Module Az.Compute -Scope CurrentUser
Install-Module Az.Network -Scope CurrentUser
```

## Included scripts and templates

| Path | Purpose | Access / impact |
|---|---|---|
| `01-Resource-Inventory/Get-AzureResourceInventory.ps1` | Export resource name, type, resource group, region and resource ID | Read-only |
| `02-Compute/Get-AzureVMInventory.ps1` | Export VM size, OS type, provisioning and power state | Read-only |
| `03-Networking/Get-AzureNetworkSecurityGroupInventory.ps1` | Export custom NSG security rules | Read-only |
| `04-Storage/main.bicep` | Deploy a StorageV2 account with secure baseline settings | Creates a billable Azure resource |

The PowerShell scripts use interactive Azure sign-in when no context exists. Use `-SubscriptionId` to select a known subscription explicitly. Always verify the active context with `Get-AzContext`.

## Quick start

Example resource inventory:

```powershell
./01-Resource-Inventory/Get-AzureResourceInventory.ps1 -SubscriptionId "<subscription-guid>"
```

Reports are written to the local `Reports/` directory with timestamped filenames. The directory and CSV files are excluded from Git.

## Bicep storage account example

The template requires a globally unique storage account name. Replace the placeholder in `04-Storage/main.bicepparam` before deployment.

Validate and preview before creating anything:

```bash
az bicep build --file 04-Storage/main.bicep
az deployment group what-if --resource-group "<resource-group>" --template-file 04-Storage/main.bicep --parameters 04-Storage/main.bicepparam
```

Deploy only after reviewing the what-if output and confirming cost, region, naming, policy and network requirements:

```bash
az deployment group create --resource-group "<resource-group>" --template-file 04-Storage/main.bicep --parameters 04-Storage/main.bicepparam
```

The template enforces HTTPS, TLS 1.2, disables anonymous blob access and disables Shared Key authorization. Public network access remains enabled; configure private endpoints or network restrictions separately to suit your architecture. Disabling Shared Key can affect legacy applications and tools, so validate compatibility before deployment.

## Safety

Read-only scripts still access tenant/subscription metadata. Protect generated reports. Bicep deployments can incur charges and change your environment; always run `what-if`, review the template, and test in a non-production subscription first. See [docs/SAFETY.md](docs/SAFETY.md).

## Validation status

The scripts and template are based on documented Azure PowerShell and Bicep patterns. They have not been executed against a live Azure subscription in this repository. Validate module/API versions, permissions, policy and outputs in a test subscription before production use.

## Planned areas

- Resource health, cost and tagging audits
- Storage account configuration and lifecycle reporting
- Backup and recovery posture
- Azure Monitor and Log Analytics queries
- RBAC and managed identity inventory
- Network topology and private endpoint reporting
- Bicep modules for repeatable, policy-aware deployments

## Official documentation

- [Azure PowerShell](https://learn.microsoft.com/en-us/powershell/azure/)
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/)
- [Bicep documentation](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/)

## License

No license has been selected. Unless a license is added, standard copyright applies and reuse/redistribution permissions are not granted.
