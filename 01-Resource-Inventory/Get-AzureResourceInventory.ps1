[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\..\Reports")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (-not (Get-Module -ListAvailable -Name Az.Accounts) -or -not (Get-Module -ListAvailable -Name Az.Resources)) {
    throw "Install required modules: Install-Module Az.Accounts, Az.Resources -Scope CurrentUser"
}
Import-Module Az.Accounts
Import-Module Az.Resources
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$context = Get-AzContext
if (-not $context) { throw "No Azure context is available." }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$reportPath = Join-Path $OutputDirectory ("Azure-Resources-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$resources = Get-AzResource
$report = $resources | Sort-Object ResourceGroupName,ResourceType,Name | Select-Object Name,ResourceGroupName,ResourceType,Location,ResourceId,SubscriptionId
$report | Export-Csv -Path $reportPath -NoTypeInformation -Encoding utf8
Write-Host "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
Write-Host "Exported $($report.Count) resources to $reportPath" -ForegroundColor Green
