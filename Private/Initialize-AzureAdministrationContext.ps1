[CmdletBinding()]
param()

function Initialize-AzureAdministrationContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$SubscriptionId,

        [Parameter()]
        [ValidatePattern('^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')]
        [string]$TenantId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$RequiredModules
    )

    foreach ($moduleName in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $moduleName)) {
            throw "Required PowerShell module '$moduleName' is not installed. Install it with: Install-Module $moduleName -Scope CurrentUser"
        }
        Import-Module -Name $moduleName -ErrorAction Stop
    }

    $context = Get-AzContext -ErrorAction SilentlyContinue
    if ($TenantId -and $context -and ([string]$context.Tenant.Id -ne $TenantId)) {
        $context = $null
    }

    if (-not $context) {
        if ($TenantId) {
            Connect-AzAccount -Tenant $TenantId -ErrorAction Stop | Out-Null
        }
        else {
            Connect-AzAccount -ErrorAction Stop | Out-Null
        }
    }

    Set-AzContext -SubscriptionId $SubscriptionId -ErrorAction Stop | Out-Null
    $context = Get-AzContext -ErrorAction Stop

    if (-not $context -or -not $context.Subscription -or ([string]$context.Subscription.Id -ne $SubscriptionId)) {
        throw "Azure context does not match requested subscription '$SubscriptionId'. No inventory was collected."
    }
    if ($TenantId -and ([string]$context.Tenant.Id -ne $TenantId)) {
        throw "Azure context tenant does not match requested tenant '$TenantId'. No inventory was collected."
    }

    Write-Verbose "Using Azure account '$($context.Account.Id)', tenant '$($context.Tenant.Id)', subscription '$($context.Subscription.Name)' ($($context.Subscription.Id))."
    return $context
}
