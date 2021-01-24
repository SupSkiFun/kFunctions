class K8sAPI
{
    static $uria = 'apis/'

    static [psobject] GetApiInfo ( [string] $mainurl )
    {
        $apis =  Invoke-RestMethod -Method Get -Uri $mainurl
        return $apis
    }

    static [psobject] GetResourceInfo ( [string] $url )
    {
        $resq = Invoke-RestMethod -Method Get -Uri $url
        $resi = $resq.resources.Where({$_.name -notmatch "/"})
        return $resi
    }

    static [pscustomobject] MakeObj (
            [string] $nom ,
            [psobject] $grv ,
            [psobject] $res ,
            [string] $prv
        )
    {
        $gvv = $grv.groupVersion

        $lo = [PSCustomObject]@{
            GroupName = $nom
            GroupVersion = $gvv
            Version = $grv.version
            PreferredVersion = ( $prv -eq $gvv ? $true : $false )
            ResourceName = $res.name
            ResourceKind = $res.kind
            ShortName = $res.shortNames
            NameSpaced = $res.namespaced
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.Kubernetes.API.Info')
        return $lo
    }
}

<#
.SYNOPSIS
Produces an object of Kubernetes API Groups and Resources.
.DESCRIPTION
Produces an object of Kubernetes API Groups and Resources via proxied connection.
Combines the output of (kubectl api-resources) and (kubectl api-versions).
See Notes and Examples.
.PARAMETER Uri
URI that has been proxied via kubectl.
.INPUTS
URI that has been proxied via kubectl.
.OUTPUTS
pscustombobject SupSkiFun.Kubernetes.API.Info
.NOTES
1.  PowerShell 7 Required because a ternary operator is used.  Using a version lower than 7 will error akin to:
        PreferredVersion = ( $prv -eq $gvv ? $true : $false )
        Unexpected token '?' in expression or statement.
2.  For the command to work properly
    Ensure that the API has been proxied, akin to:  kubectl proxy --port 8888 &
    Dot Source the Advanced Function:  . ./Your/Path/GetK8sAPIInfo.ps1
    Run the command, returning the information into a variable:  $myVar = Get-K8sAPIInfo
3.  The DefaultDisplayPropertySet = "GroupName","GroupVersion","ResourceKind","ResourceName"
    To see all properties, issue either:
        $myVar | Format-List -Property *
        $myVar | Select-Object -Property *
.EXAMPLE
Before this Advanced Function will work, a proxy to the API must be configured.

Note any free port above 1024 can be used; if using a port different than 8888, substitute accordingly in both references below.
    kubectl proxy --port 8888 &

Once the proxy is established:
    $myVar = Get-K8sAPIInfo -Uri http://localhost:8888

Display the Default Property Set of all Groups / Resources:
    $myVar

Display all Properties of all Groups / Resources:
    $myVar | Format-List -Property *

Display all Preferred Version Groups / Resources:
    $myVar | Where-Object -Property PreferredVersion -eq $true
        or
    $myVar | Where-Object -Property PreferredVersion -eq $true | fl *

Display all Groups / Resources within the apps group:
    $myVar | Where-Object -Property GroupName -eq apps
        or
    $myVar | Where-Object -Property GroupName -eq apps | fl *

Display all Groups / Resources matching the ResourceKind Role:
    $myVar | Where-Object -Property ResourceKind -match role
        or
    $myVar | Where-Object -Property ResourceKind -match role | fl *
#>

Function Get-K8sAPIInfo
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $true , ValueFromPipeline = $true)]
        [Uri] $Uri
    )

    Begin
    {
        if ( ([uri] $uri).IsAbsoluteUri -eq $false )
        {
            Write-Output "Terminating.  Non-valid URL detected.  Submitted URL:  $uri"
            break
        }

        $mainurl = ($($Uri.AbsoluteUri)+$([K8sAPI]::uria))
    }

    Process
    {
        $apis = [K8sAPI]::GetApiInfo($mainurl)

        foreach ($api in $apis.groups)
        {
            $prv = $api.preferredVersion.groupVersion
            $grvs = $api.versions
            foreach ($grv in $grvs)
            {
                $url = $($mainurl)+$($grv.groupVersion)
                $resi = [K8sAPI]::GetResourceInfo($url)
                foreach ($res in $resi)
                {
                    $lo = [K8sAPI]::MakeObj($api.name , $grv , $res , $prv)
                    $lo
                }
            }
        }
    }

    End
    {
        $TypeData = @{
            TypeName = 'SupSkiFun.Kubernetes.API.Info'
            DefaultDisplayPropertySet = "GroupName","GroupVersion","ResourceKind","ResourceName"
        }
        Update-TypeData @TypeData -Force
    }
}