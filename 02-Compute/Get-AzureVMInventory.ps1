[CmdletBinding()]
param(
    [string]$SubscriptionId,
    [string]$OutputDirectory = (Join-Path $PSScriptRoot "..\..\Reports")
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (-not (Get-Module -ListAvailable -Name Az.Accounts) -or -not (Get-Module -ListAvailable -Name Az.Compute)) {
    throw "Install required modules: Install-Module Az.Accounts, Az.Compute -Scope CurrentUser"
}
Import-Module Az.Accounts
Import-Module Az.Compute
if (-not (Get-AzContext)) { Connect-AzAccount | Out-Null }
if ($SubscriptionId) { Set-AzContext -SubscriptionId $SubscriptionId | Out-Null }
$context = Get-AzContext
if (-not $context) { throw "No Azure context is available." }
New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$reportPath = Join-Path $OutputDirectory ("Azure-VMs-{0}.csv" -f (Get-Date -Format "yyyyMMdd-HHmmss"))
$vms = Get-AzVM -Status
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
$report | Export-Csv -Path $reportPath -NoTypeInformation -Encoding utf8
Write-Host "Subscription: $($context.Subscription.Name)"
Write-Host "Exported $($report.Count) VMs to $reportPath" -ForegroundColor Green
