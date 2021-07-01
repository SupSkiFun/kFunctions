using module ./kClass.psm1

<#
Help info here

cd C:\Users\ja0310\scripts\AdvFunc\kFunctions\3.4.5.6
$uri = 'http://127.0.0.1:8888'
. .\GetPods.ps1
. .\GetNameSpaces.ps1
#>

Function Get-NameSpaces
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [Uri] $Uri
    )

    Begin
    {
        if (-not([K8sAPI]::CheckUri($uri)))
        {
            Write-Output $(([K8sAPI]::mesg) + $uri)
            break
        }

        $urln = ($($Uri.AbsoluteUri)+$([K8sAPI]::urin))
    }

    Process
    {
        $apin = [K8sAPI]::GetApiInfo($urln)
        foreach ($ns in $apin.items)
        {
            $lo = [K8sAPI]::MakeNameSpaceObj($ns)
            $lo
        }

    }
}