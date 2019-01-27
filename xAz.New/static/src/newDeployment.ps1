#REQUIRES -Version 5.0
#REQUIRES #-Modules
#REQUIRES #-RunAsAdministrator

function New-Deployment {
    <#
    .SYNOPSIS
    Create the resource

    .DESCRIPTION


    .EXAMPLE
    C:\PS>New-<%= $PLASTER_PARAM_Prefix %>Deployment -ResourceName $ResourceName -ResourceGroupName $RGName
    Example of how to use this cmdlet

    .PARAMETER ComponentName
    Component Name
    Can be generated by using Get-<%= $PLASTER_PARAM_Prefix %>Name
    Uses ParameterSet ComponentName

    .PARAMETER ResourceGroupName
    Resource Group Name

    .PARAMETER Location
    Name of Azure Location - e.g. WestEurope
    [ValidateScript( { (Get-AzureRmLocation).Location -contains $_ } )]

    .PARAMETER WhatIf
    Dry run of script, returns input values

    .PARAMETER Confirm
    Before impacting system ask to confirm
    #>


    [CmdletBinding(
        SupportsShouldProcess = $True,
        PositionalBinding = $True,
        DefaultParameterSetName = "Default"
    )]

    [OutputType([PSCustomObject])]
    param(
        [Parameter(
            Mandatory,
            Position = 0,
            HelpMessage = "Enter name of Resource"
        )]
        [string] $ResourceName,

        [Parameter(
            Mandatory,
            Position = 1,
            HelpMessage = "Enter name of Resource Group"
        )]
        [string] $ResourceGroupName,

        [Parameter(
            Mandatory,
            Position = 3,
            HelpMessage = "Enter name of Azure location - e.g. WestEurope"
        )]
        [ValidateScript( { (Get-AzureRmLocation).Location -contains $_ } )]
        [Alias("Loc")]
        [string] $Location
    )

    begin {

    }

    process {

        $TemplateUri = Get-<%= $PLASTER_PARAM_Prefix %>Template

        if ([string]::IsNullOrEmpty($ResourceName)) {

        }
        Write-Verbose "[$(Get-Date)] ResourceName $ResourceName"

        $ResourceGroup = Get-AzureRmResourceGroup $ResourceGroupName -ErrorAction Stop
        Write-Verbose "[$(Get-Date)] ResourceGroup $($ResourceGroup.ResourceGroupName)"

        $TemplateParameterObject = @{
            Name              = $ResourceName
            ResourceGroupName = $ResourceGroupName
        }

        try {

            if ($PSCmdlet.ShouldProcess($ResourceGroupName, $ComponentName)) {

                $Deployment = New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateUri $TemplateUri -TemplateParameterObject $TemplateParameterObject -ErrorVariable ErrorMessages

                if ($ErrorMessages) {
                    Write-Output '', 'Template deployment returned the following errors:', @(@($ErrorMessages) | ForEach-Object { $_.Exception.Message.TrimEnd("`r`n") })
                }
                else {
                    $return = Get-DeploymentOutput $Deployment.Outputs
                }
            }

            $return
        }
        catch [Exception] {
            Write-Error "$($_.Exception) found"
            Write-Verbose "$($_.ScriptStackTrace)"
            throw $_
        }
    }

    end {
    }
}

# Export-ModuleMember -Function New-<%= $PLASTER_PARAM_Prefix %>Deployment
# New-<%= $PLASTER_PARAM_Prefix %>Deployment -ResourceName -ResourceGroupName

function Get-DeploymentOutput {
    <#
        .SYNOPSIS
            Takes Outputs from Arm Template deployment and generates a pscustomobject.

        .NOTES
            Outputs is Dictionary`2  needs enumerator
            Output value has odd value key again -> $output.Value.Value

            [DBG]: PS C:> $output

            Key              Value
            ---              -----
            virtualMachineId Microsoft.Azure.Commands.ResourceManager.Cmdlets.SdkModels.DeploymentVariable

            [DBG]: PS C:> $output.Value

            Type   Value
            ----   -----
            String /subscriptions/<subscription>/resourceGroups/<resourceGroup>/providers/Microsoft.<Proivder>/<Resource>/<Value>

            $output.value.value
    #>
    [CmdletBinding()]
    param(
        $Outputs
    )

    if (-Not $Outputs) {
        Write-Error "[$(Get-Date)] Deployment output can not be parsed ´n $Deployment"
        return
    }
    else {
        try {
            $return = [PSCustomObject]@{}
            $enum = $Outputs.GetEnumerator()

            while ($enum.MoveNext()) {
                $current = $enum.Current
                $return | Add-Member -MemberType NoteProperty -Name $current.Key -Value $current.Value.Value
            }
            $return
        }
        catch {
            Write-Verbose "[$(Get-Date)] Unable to parse"
            return $Outputs
        }
    }
}