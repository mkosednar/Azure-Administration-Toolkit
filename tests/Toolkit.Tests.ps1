BeforeAll {
    $repoRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $repoRoot "Private/Initialize-AzureAdministrationContext.ps1")
    . (Join-Path $repoRoot "Private/ConvertTo-AzureVMInventoryRecord.ps1")

    # Lightweight command stubs let Pester mock Az cmdlets without installing Az modules.
    function Get-AzContext {
        param([string]$ErrorAction)
    }
    function Connect-AzAccount {
        param([string]$Tenant, [string]$ErrorAction)
    }
    function Set-AzContext {
        param([string]$SubscriptionId, [string]$ErrorAction)
    }
}

Describe "PowerShell parser" {
    It "parses every PowerShell script without syntax errors" {
        $repoRoot = Split-Path -Parent $PSScriptRoot
        $files = Get-ChildItem -Path $repoRoot -Filter "*.ps1" -Recurse
        foreach ($file in $files) {
            $tokens = $null
            $errors = $null
            [System.Management.Automation.Language.Parser]::ParseFile($file.FullName, [ref]$tokens, [ref]$errors) | Out-Null
            $errors | Should -BeNullOrEmpty -Because $file.FullName
        }
    }
}

Describe "Initialize-AzureAdministrationContext" {
    BeforeEach {
        $script:TestContext = [pscustomobject]@{
            Account = [pscustomobject]@{ Id = "test@example.invalid" }
            Tenant = [pscustomobject]@{ Id = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" }
            Subscription = [pscustomobject]@{ Id = "11111111-1111-1111-1111-111111111111"; Name = "Test subscription" }
        }
        Mock Get-Module { [pscustomobject]@{ Name = $Name } } -ParameterFilter { $ListAvailable }
        Mock Import-Module {}
        Mock Get-AzContext { $script:TestContext }
        Mock Connect-AzAccount {}
        Mock Set-AzContext {}
    }

    It "rejects an invalid subscription ID before contacting Azure" {
        { Initialize-AzureAdministrationContext -SubscriptionId "not-a-guid" -RequiredModules @("Az.Accounts") } | Should -Throw
        Should -Invoke Get-AzContext -Times 0
        Should -Invoke Set-AzContext -Times 0
    }

    It "imports required modules and selects the requested subscription" {
        $context = Initialize-AzureAdministrationContext -SubscriptionId "11111111-1111-1111-1111-111111111111" -RequiredModules @("Az.Accounts", "Az.Resources")
        $context.Subscription.Id | Should -Be "11111111-1111-1111-1111-111111111111"
        Should -Invoke Import-Module -Times 2
        Should -Invoke Set-AzContext -Times 1 -ParameterFilter { $SubscriptionId -eq "11111111-1111-1111-1111-111111111111" }
    }

    It "fails closed when the selected context does not match the requested subscription" {
        $script:TestContext.Subscription.Id = "22222222-2222-2222-2222-222222222222"
        { Initialize-AzureAdministrationContext -SubscriptionId "11111111-1111-1111-1111-111111111111" -RequiredModules @("Az.Accounts") } | Should -Throw "*does not match requested subscription*"
    }

    It "fails with an installation hint when a required module is missing" {
        Mock Get-Module {
            if ($Name -eq "Az.Resources") { return $null }
            [pscustomobject]@{ Name = $Name }
        } -ParameterFilter { $ListAvailable }
        { Initialize-AzureAdministrationContext -SubscriptionId "11111111-1111-1111-1111-111111111111" -RequiredModules @("Az.Accounts", "Az.Resources") } | Should -Throw "*Install-Module Az.Resources*"
    }

    It "signs in to the requested tenant and fails closed if the resulting tenant still differs" {
        $requestedTenant = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
        {
            Initialize-AzureAdministrationContext -SubscriptionId "11111111-1111-1111-1111-111111111111" -TenantId $requestedTenant -RequiredModules @("Az.Accounts")
        } | Should -Throw "*tenant does not match requested tenant*"
        Should -Invoke Connect-AzAccount -Times 1 -ParameterFilter { $Tenant -eq $requestedTenant }
    }
}

Describe "ConvertTo-AzureVMInventoryRecord" {
    It "projects the available VM inventory fields" {
        $vm = [pscustomobject]@{
            Name = "vm-test"
            ResourceGroupName = "rg-test"
            Location = "westeurope"
            HardwareProfile = [pscustomobject]@{ VmSize = "Standard_B2s" }
            Statuses = @([pscustomobject]@{ Code = "PowerState/running"; DisplayStatus = "VM running" })
            StorageProfile = [pscustomobject]@{ OsDisk = [pscustomobject]@{ OsType = "Linux" } }
            ProvisioningState = "Succeeded"
            Id = "/subscriptions/test/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm-test"
        }

        $record = ConvertTo-AzureVMInventoryRecord -VirtualMachine $vm

        $record.Name | Should -Be "vm-test"
        $record.VmSize | Should -Be "Standard_B2s"
        $record.PowerState | Should -Be "VM running"
        $record.OsType | Should -Be "Linux"
        $record.ProvisioningState | Should -Be "Succeeded"
    }

    It "returns null for missing nested VM properties without throwing" {
        $vm = [pscustomobject]@{
            Name = "vm-incomplete"
            ResourceGroupName = "rg-test"
            Location = "westeurope"
            HardwareProfile = $null
            Statuses = $null
            StorageProfile = $null
            ProvisioningState = $null
            Id = "/subscriptions/test/resourceGroups/rg-test/providers/Microsoft.Compute/virtualMachines/vm-incomplete"
        }

        { $script:record = ConvertTo-AzureVMInventoryRecord -VirtualMachine $vm } | Should -Not -Throw
        $record.VmSize | Should -BeNullOrEmpty
        $record.PowerState | Should -BeNullOrEmpty
        $record.OsType | Should -BeNullOrEmpty
    }

    It "handles a storage profile without an OS disk" {
        $vm = [pscustomobject]@{
            Name = "vm-no-disk"
            ResourceGroupName = "rg-test"
            Location = "westeurope"
            HardwareProfile = [pscustomobject]@{ VmSize = "Standard_B2s" }
            Statuses = @()
            StorageProfile = [pscustomobject]@{ OsDisk = $null }
            ProvisioningState = "Succeeded"
            Id = "vm-no-disk"
        }

        $record = ConvertTo-AzureVMInventoryRecord -VirtualMachine $vm
        $record.OsType | Should -BeNullOrEmpty
    }
}
