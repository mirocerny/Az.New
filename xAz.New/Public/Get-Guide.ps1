
function Get-Guide {
    [CmdletBinding()]
    param (
    )
    process {
        Get-xAzUri GUIDE
    }
}