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
$context = Initialize-AzureAdministrationContext -SubscriptionId $SubscriptionId -TenantId $TenantId -RequiredModules @("Az.Accounts", "Az.Network")
New-Item -ItemType Directory -Path $OutputDirectory -Force -ErrorAction Stop | Out-Null
$reportPath = Join-Path $OutputDirectory ("Azure-NSG-Rules-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$groups = Get-AzNetworkSecurityGroup -ErrorAction Stop
$report = foreach ($nsg in $groups) {
    foreach ($rule in $nsg.SecurityRules) {
        [pscustomobject]@{
            NetworkSecurityGroup = $nsg.Name
            ResourceGroupName = $nsg.ResourceGroupName
            Location = $nsg.Location
            RuleName = $rule.Name
            Priority = $rule.Priority
            Direction = $rule.Direction
            Access = $rule.Access
            Protocol = $rule.Protocol
            SourceAddressPrefix = (@($rule.SourceAddressPrefixes) + @($rule.SourceAddressPrefix) | Where-Object { $_ }) -join ";"
            SourcePortRange = (@($rule.SourcePortRanges) + @($rule.SourcePortRange) | Where-Object { $_ }) -join ";"
            DestinationAddressPrefix = (@($rule.DestinationAddressPrefixes) + @($rule.DestinationAddressPrefix) | Where-Object { $_ }) -join ";"
            DestinationPortRange = (@($rule.DestinationPortRanges) + @($rule.DestinationPortRange) | Where-Object { $_ }) -join ";"
        }
    }
}
$report | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop
Write-Host "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
Write-Host "Exported $(@($report).Count) custom NSG rules to $reportPath" -ForegroundColor Green
