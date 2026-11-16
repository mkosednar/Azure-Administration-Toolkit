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
$context = Initialize-AzureAdministrationContext -SubscriptionId $SubscriptionId -TenantId $TenantId -RequiredModules @("Az.Accounts", "Az.Compute")
New-Item -ItemType Directory -Path $OutputDirectory -Force -ErrorAction Stop | Out-Null
$reportPath = Join-Path $OutputDirectory ("Azure-VMs-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$vms = Get-AzVM -Status -ErrorAction Stop
$report = foreach ($vm in $vms) {
    [pscustomobject]@{
        Name = $vm.Name
        ResourceGroupName = $vm.ResourceGroupName
        Location = $vm.Location
        VmSize = $vm.HardwareProfile.VmSize
        PowerState = (($vm.Statuses | Where-Object Code -like "PowerState/*" | Select-Object -First 1).DisplayStatus)
        OsType = $vm.StorageProfile.OsDisk.OsType
        ProvisioningState = $vm.ProvisioningState
        Id = $vm.Id
    }
}
$report | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop
Write-Host "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
Write-Host "Exported $(@($report).Count) VMs to $reportPath" -ForegroundColor Green
