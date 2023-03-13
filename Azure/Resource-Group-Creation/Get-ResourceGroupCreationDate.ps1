#requires -version 7
#requires -PSEdition Core

<#

.SYNOPSIS
  Retrieves the age of Resource Groups
.DESCRIPTION
  The Get-ResourceGroupCreationDate.ps1 script retrieves the age of all or a subset of Resource Groups within an Azure environment
.PARAMETER SubscriptionID
    (Optional) Provide a SubscriptionID to limit the search scope to a single Subscription. SubscriptionID cannot be used with SubscriptionNamePattern or SubscriptionAll.
.PARAMETER SubscriptionNamePattern
    (Optional) Provide a portion of the name that will be wildcard searched.  For example, "sandbox" finds all subscriptions that contain "sandbox". SubscriptionNamePattern cannot be used with SubscriptionID or SubscriptionAll.
.PARAMETER SubscriptionAll
    (Optional) Switch to search all subscriptions present within the tenant. SubscriptionAll cannot be used with SubscriptionNamePattern or SubscriptionID.
.PARAMETER Interactive
    (Optional) Enables an Interactive login instead of using the currently authenticated credentials
.PARAMETER IncludeCost
    (Optional) Retrieves the current Month to Day cost of each Resource Group
.PARAMETER IncludeDefault
    (Optional) By default, the script excludes Azure default Resource Groups.  To include these default Resource Groups, use this switch
.INPUTS
    None
      You can't send objects down from a pipeline to this command
.OUTPUTS
    CSV File at the Present Working Directory titled `Results-Get-ResourceGroupCreationDate.csv`
.NOTES
  Version:        2.1.0  
  Author:         Brandon Casey  
  Creation Date:  2022.09.22  
  Updated Date:   2023.03.13  

.EXAMPLE
  Get-ResourceGroupCreationDate.ps1 -SubscriptionID "12345678-1234-1234-1234-123456789123" -IncludeCost

.EXAMPLE
  Get-ResourceGroupCreationDate.ps1 -SubscriptionNamePattern "sandbox" -Interactive

.EXAMPLE
  Get-ResourceGroupCreationDate.ps1 -SubscriptionAll -Interactive -IncludeCost

.EXAMPLE
  Get-ResourceGroupCreationDate.ps1 -SubscriptionID "12345678-1234-1234-1234-123456789123" -Interactive -IncludeCost -IncludeDefault

#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------
using namespace System.Collections.Generic

[CmdletBinding(
  PositionalBinding = $false,
  DefaultParameterSetName = "SubID")]

param (
  [Parameter(Mandatory = $true,
    ParameterSetName = 'SubID')]
  [Alias("SubID")]
  [string]$SubscriptionID,

  [Parameter(Mandatory = $true,
    ParameterSetName = 'SubPattern')]
  [Alias("SubPattern")]
  [string]$SubscriptionNamePattern,

  [Parameter(Mandatory = $true,
    ParameterSetName = 'SubAll')]
  [Alias("SubAll")]
  [switch]$SubscriptionAll,

  [Parameter(Mandatory = $false)]
  [switch]$Interactive,

  [Parameter(Mandatory = $false)]
  [switch]$IncludeCost,

  [Parameter(Mandatory = $false)]
  [switch]$IncludeDefault
)

$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'
#-----------------------------------------------------------[Functions]------------------------------------------------------------

# This function retrieves the information from the Resource Group.  A REST API call is needed as the creation date of Resource Groups are only exposed through REST
function Get-RGInfo {
  param (
    [string]$SubscriptionID,
    [string]$SubscriptionName
  )

  Write-Information "Evaluating Subscription: $SubscriptionName"

  $headers.Remove("Authorization") | out-null
  $headers.Add("Authorization", "Bearer $((Get-AzAccessToken).Token)")

  $RGListResponse = Invoke-RestMethod "https://management.azure.com/subscriptions/$SubscriptionID/resourcegroups?api-version=2021-04-01&`$expand=createdTime" -Method 'GET' -Headers $headers

  Write-Information "Found $($RGListResponse.value.Count) Resource Groups. Gathering Information..."

  $i = 0
  foreach ($RG in $RGListResponse.value) {
    Write-Information "Looking at Resource Group $i of $($RGListResponse.value.Count)"

    $RGResultObj = New-Object -TypeName psobject
    $i++

    # By default, the script filters out the default Resource Groups created by Azure, but can be included through an optional parameter switch.
    if ($IncludeDefault -or ((Compare-DefaultName -RGName $RG.name) -eq $false)) {
      $RGResultObj | Add-Member -MemberType NoteProperty -Name ResourceGroupName -value $RG.name
      $RGResultObj | Add-Member -MemberType NoteProperty -Name SubscriptionName -value $SubscriptionName
      $RGResultObj | Add-Member -MemberType NoteProperty -Name CreationTime -value $RG.createdTime

      # If the user includes the switch to include the cost, the script performs an additional REST API call to retrieve the call.
      if ($IncludeCost) {
        $cost = Get-CurrentMonthCost -ResourceGroupName $RG.name
        $RGResultObj | Add-Member -MemberType NoteProperty -Name CurrentMonthCost -value $cost
      }
      $resultList.Add($RGResultObj)
    }
  }
}

# This function retrieves the current Month to Day cost of the Resource Group
function Get-CurrentMonthCost {
  param (
    [string]$ResourceGroupName
  )

  # This setups the JSON body needed to make the REST API call to Azure's Cost Management
  $body = @{
    "type"      = "ActualCost"
    "timeframe" = "MonthToDate"
    "dataSet"   = @{
      "granularity" = "Monthly"
      "aggregation" = @{
        "totalCost" = @{
          "name"     = "Cost"
          "function" = "Sum"
        }
      }
    }
  }


  $done = $false

  # This performs the action of retrieving the cost from Azure's Cost Management.  Due to rate limiting, a retry method was built into the block of code
  while ($done -ne $true) {
    try {
      $response = Invoke-RestMethod "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.CostManagement/query?api-version=2021-10-01" -Method 'POST' -Headers $headers -Body ($body | ConvertTo-Json -Depth 100) -ContentType "application/json"
      $done = $true
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException] {
      if ($_.Exception.Response.StatusCode -eq 429) {
        $delay = 1000
        Write-Verbose -Message "Retry Caught, delaying $delay ms"
        Start-Sleep -Milliseconds $delay
      }
      else {
        "Unknown Error"
        $done = $true
      }
    }
    catch {
      "Unknown Error"
      $done = $true
    }
  }

  try {
    $cost = $response.properties.rows[0][0]
  }
  catch {
    $cost = 0
  }

  return [math]::Round($cost, 2)
}

# This function provides a comparison between function between the default Azure Resource Groups (that do not incur costs) and the provided Azure Resource Group
function Compare-DefaultName {
  param (
    [string]$RGName
  )

  $DefaultRGNameSet = "DefaultResourceGroup", "NetworkWatcherRG", "cloud-shell-storage"

  # Cycles through each name in the above variable to validate the name does not match (Note: similiar names are included. Ex: DefaultResourceGroup and DefaultResourceGroup-CUS)
  foreach ($DefaultRGName in $DefaultRGNameSet) {
    if ($RGName -match $DefaultRGName) {
      return $true
    }
  }

  return $false

}
#------------------------------------------------------------[Testing]-------------------------------------------------------------
#$SubscriptionID = $null
#$SubscriptionNamePattern = "Test"
#$SubscriptionAll = $true
#$Interactive = $null
#$IncludeCost = $true
#$IncludeDefault = $true
#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Creates a blank list to be populated with Resource Groups
$resultList = [List[PSObject]]::new()

# Configures authentication to Azure REST APIs
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/json")

# Validates if the user used the switch "interactive".  If so, allow the user to connect to Azure manually
if ($Interactive) {
  Connect-AzAccount
}

# Starts by checking if the parameter "SubscriptionID" was used
if ("" -ne $SubscriptionID) {
  # Checks if the user typed in the Subscription ID wrong or is not authenticated correctly
  try {
    $SubscriptionName = (Get-AzSubscription -SubscriptionId $SubscriptionID).Name
  }
  catch {
    throw "The subscription $SubscriptionID was not found.  Are you authenticated to the correct tenant?"
  }

  # Relays information to function to get information
  Get-RGInfo -SubscriptionID $SubscriptionID -SubscriptionName $SubscriptionName
}

# If "SubscriptionID" was not used, check if SubscriptionNamePattern was used
elseif ("" -ne $SubscriptionNamePattern) {
  foreach ($TenantSubscription in Get-AzSubscription) {
    # Verifies the pattern matches the Subscription name and that the subscription does not belong to a different tenant through the use of Guest accounts
    if (($TenantSubscription.Name.ToLower() -match $SubscriptionNamePattern.ToLower()) -and ($TenantSubscription.TenantId -eq ((Get-AzAccessToken).TenantId))) {
      # Relays information to function to get information
      Get-RGInfo -SubscriptionID $TenantSubscription.Id -SubscriptionName $TenantSubscription.Name
    }
  }
}
# If neither of the above go through, check if the "SubscriptionAll" switch was used
elseif ($SubscriptionAll) {
  foreach ($TenantSubscription in Get-AzSubscription) {
    if ($TenantSubscription.TenantId -eq ((Get-AzAccessToken).TenantId)) {
      Get-RGInfo -SubscriptionID $TenantSubscription.Id -SubscriptionName $TenantSubscription.Name
    }
  }
}
else {
  Write-Error "Unknown Option Selected"
}

# Export the results to the Present Working Directory
$resultList | Export-Csv -Path "Results-Get-ResourceGroupCreationDate.csv" -Force