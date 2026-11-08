[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\..\Reports")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (-not (Get-Module -ListAvailable -Name Az.Accounts) -or -not (Get-Module -ListAvailable -Name Az.Network)) {
    throw "Install required modules: Install-Module Az.Accounts, Az.Network -Scope CurrentUser"
}
Import-Module Az.Accounts
Import-Module Az.Network
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$context = Get-AzContext
if (-not $context) { throw "No Azure context is available." }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$reportPath = Join-Path $OutputDirectory ("Azure-NSG-Rules-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$groups = Get-AzNetworkSecurityGroup
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
$report | Export-Csv -Path $reportPath -NoTypeInformation -Encoding utf8
Write-Host "Subscription: $($context.Subscription.Name)"
Write-Host "Exported $($report.Count) custom NSG rules to $reportPath" -ForegroundColor Green
