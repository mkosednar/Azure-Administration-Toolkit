function ConvertTo-AzureVMInventoryRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$VirtualMachine
    )

    process {
        $vmSize = $null
        if ($null -ne $VirtualMachine.HardwareProfile) {
            $vmSize = $VirtualMachine.HardwareProfile.VmSize
        }

        $powerState = $null
        if ($null -ne $VirtualMachine.Statuses) {
            $powerStatus = $VirtualMachine.Statuses |
                Where-Object { $null -ne $_ -and $_.Code -like "PowerState/*" } |
                Select-Object -First 1
            if ($null -ne $powerStatus) {
                $powerState = $powerStatus.DisplayStatus
            }
        }

        $osType = $null
        if ($null -ne $VirtualMachine.StorageProfile -and $null -ne $VirtualMachine.StorageProfile.OsDisk) {
            $osType = $VirtualMachine.StorageProfile.OsDisk.OsType
        }

        [pscustomobject]@{
            Name = $VirtualMachine.Name
            ResourceGroupName = $VirtualMachine.ResourceGroupName
            Location = $VirtualMachine.Location
            VmSize = $vmSize
            PowerState = $powerState
            OsType = $osType
            ProvisioningState = $VirtualMachine.ProvisioningState
            Id = $VirtualMachine.Id
        }
    }
}
