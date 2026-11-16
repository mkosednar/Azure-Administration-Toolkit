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
    $vmSize = $null
    if ($null -ne $vm.HardwareProfile) {
        $vmSize = $vm.HardwareProfile.VmSize
    }

    $powerState = $null
    $powerStatus = $vm.Statuses | Where-Object { $_.Code -like "PowerState/*" } | Select-Object -First 1
    if ($null -ne $powerStatus) {
        $powerState = $powerStatus.DisplayStatus
    }

    $osType = $null
    if ($null -ne $vm.StorageProfile -and $null -ne $vm.StorageProfile.OsDisk) {
        $osType = $vm.StorageProfile.OsDisk.OsType
    }

    [pscustomobject]@{
        Name = $vm.Name
        ResourceGroupName = $vm.ResourceGroupName
        Location = $vm.Location
        VmSize = $vmSize
        PowerState = $powerState
        OsType = $osType
        ProvisioningState = $vm.ProvisioningState
        Id = $vm.Id
    }
}
$report | Export-Csv -LiteralPath $reportPath -NoTypeInformation -Encoding utf8 -ErrorAction Stop
Write-Host "Subscription: $($context.Subscription.Name) ($($context.Subscription.Id))"
Write-Host "Exported $(@($report).Count) VMs to $reportPath" -ForegroundColor Green
