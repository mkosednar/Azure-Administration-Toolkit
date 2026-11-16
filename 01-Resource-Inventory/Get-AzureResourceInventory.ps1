[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$SubscriptionId,
    [Parameter()]
    [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
    [string]$TenantId,
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\..\Reports")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
. (Join-Path $PSScriptRoot "..\Private\Initialize-AzureAdministrationContext.ps1")
$context = Initialize-AzureAdministrationContext -SubscriptionId $SubscriptionId -TenantId $TenantId -RequiredModules @("Az.Accounts", "Az.Resources")
New-Item -ItemType Directory -Path $OutputDirectory -Force -ErrorAction Stop | Out-Null
$reportPath = Join-Path $OutputDirectory ("Azure-Resources-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$resources = Get-AzResource -ErrorAction Stop
$report = $resources | Sort-Object ResourceGroupName,ResourceType,Name | Select-Object Name,ResourceGroupName,ResourceType,Location,ResourceId,SubscriptionId
$report | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop
Write-Host "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
Write-Host "Exported $(@($report).Count) resources to $reportPath" -ForegroundColor Green
