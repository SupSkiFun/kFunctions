using module .\kClass.psm1

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
1.  Command works both locally (Linux) and remotely (Linux or Windows).
2.  For this Advanced Function to work properly:
    a) Ensure that the API has been proxied:
        Start-Job -ScriptBlock {kubectl proxy --port 8888}
    b) Run the command, returning the information into a variable:
        $myVar = Get-K8sAPIInfo -Uri http://127.0.0.1:8888
3.  The DefaultDisplayPropertySet = "GroupName","GroupVersion","ResourceKind","ResourceName"
    To see all properties, issue either:
        $myVar | Format-List -Property *
        $myVar | Select-Object -Property *
4. If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.
5. For PowerShell 7, ensure the use of 127.0.0.1 instead of localhost.  Using localhost is far slower.
.EXAMPLE
Please Read:

Note: Any free port above 1024 can be used; if using a port different than 8888, substitute accordingly.
Note: If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.

Before this Advanced Function will work, a proxy to the API must be configured.
    Start-Job -ScriptBlock {kubectl proxy --port 8888}

Once the proxy is established:
    $myVar = Get-K8sAPIInfo -Uri http://127.0.0.1:8888

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
        if (-not([K8sAPI]::CheckUri($uri)))
        {
            Write-Output $(([K8sAPI]::mesg) + $uri)
            break
        }

        $urla = ($($Uri.AbsoluteUri)+$([K8sAPI]::uria))
        $urlc = ($($Uri.AbsoluteUri)+$([K8sAPI]::uric))
    }

    Process
    {
        $apic = [K8sAPI]::GetApiInfo($urlc)
        $rr = $apic.resources |
            Where-Object -Property Name -NotMatch "/"
        foreach ($ap in $rr)
        {
            $lo = [K8sAPI]::MakeObj($apic.kind , $apic.groupVersion , $ap )
            $lo
        }

        $apis = [K8sAPI]::GetApiInfo($urla)
        foreach ($api in $apis.groups)
        {
            $prv = $api.preferredVersion.groupVersion
            $grvs = $api.versions
            foreach ($grv in $grvs)
            {
                $url = $($urla)+$($grv.groupVersion)
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

<#
.SYNOPSIS
Produces an object of Kubernetes NameSpaces.
.DESCRIPTION
Produces an object of Kubernetes Namespaces via proxied connection.
See Notes and Examples.
.PARAMETER Uri
URI that has been proxied via kubectl.
.INPUTS
URI that has been proxied via kubectl.
.OUTPUTS
pscustombobject SupSkiFun.Kubernetes.NameSpace.Info
.NOTES
1.  Command works both locally (Linux) and remotely (Linux or Windows).
2.  For this Advanced Function to work properly:
    a) Ensure that the API has been proxied:
        Start-Job -ScriptBlock {kubectl proxy --port 8888}
    b) Run the command, returning the information into a variable:
        $myVar = Get-K8sNamespace -Uri http://127.0.0.1:8888
3. If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.
4. For PowerShell 7, ensure the use of 127.0.0.1 instead of localhost.  Using localhost is far slower.
.EXAMPLE
Please Read:

Note: Any free port above 1024 can be used; if using a port different than 8888, substitute accordingly.
Note: If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.

Before this Advanced Function will work, a proxy to the API must be configured.
    Start-Job -ScriptBlock {kubectl proxy --port 8888}

Once the proxy is established:
    Get-K8sNamespace -Uri http://127.0.0.1:8888
#>

Function Get-K8sNamespace
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

<#
.SYNOPSIS
Returns a specified Kubernetes Resource.
.DESCRIPTION
Returns a specified Kubernetes Resource across all NameSpaces.
See Notes and Examples.
.PARAMETER Uri
Mandatory.  URI that has been proxied via kubectl.
.PARAMETER ResourceName
Mandatory.  v1 API Resource to retrieve.  One of:  bindings, componentstatuses,
configmaps, endpoints, events, limitranges, namespaces, nodes,
persistentvolumeclaims, persistentvolumes, pods, podtemplates,
replicationcontrollers, resourcequotas, secrets, serviceaccounts, or services
.PARAMETER DetailLevel
Optional.  Least to most verbose:  Regular, High, or Full.  Defaults to Regular.
.INPUTS
URI that has been proxied via kubectl.
.OUTPUTS
pscustombobject
.NOTES
1.  Command works both locally (Linux) and remotely (Linux or Windows).
2.  For this Advanced Function to work properly:
    a) Ensure that the API has been proxied:
      Start-Job -ScriptBlock {kubectl proxy --port 8888}
    b) Run the command, returning the information into a variable:
      $myVar = Get-K8sObject -ResourceName services -Uri http://127.0.0.1:8888
3. With microK8s try 'microk8s kubectl' in place of 'kubectl'.
4. Ensure the use of 127.0.0.1 instead of localhost.
.EXAMPLE
Please Read:

Note: Any free port above 1024 can be used; if using a port different than 8888, substitute accordingly.
Note: If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.

Before this Advanced Function will work, a proxy to the API must be configured.
    Start-Job -ScriptBlock {kubectl proxy --port 8888}

Once the proxy is established (Regular DetailLevel):
    $myVar = Get-K8sObject -ResourceName services -Uri http://127.0.0.1:8888
    $myvar
    $myvar.annotations
    $myvar.annotations | Format-List *

Once the proxy is established (Full DetailLevel):
    $myVar = Get-K8sObject -ResourceName services -Uri http://127.0.0.1:8888 -DetailLevel Full
    $myvar
    $myVar | Format-List *
    $myVar | ConvertTo-Json -Depth 20
#>

Function Get-K8sObject
{
    [cmdletbinding()]
    Param
    (
        [Parameter(Mandatory = $false)]
        [ValidateSet("Regular", "High", "Full")]
        [String] $DetailLevel = "Regular",

        [Parameter(Mandatory = $true)]
        [ValidateSet(
            "bindings",
            "componentstatuses",
            "configmaps",
            "endpoints",
            "events",
            "limitranges",
            "namespaces",
            "nodes",
            "persistentvolumeclaims",
            "persistentvolumes",
            "pods",
            "podtemplates",
            "replicationcontrollers",
            "resourcequotas",
            "secrets",
            "serviceaccounts",
            "services"
        )]
        [String] $ResourceName,

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

        $urlr = ($($Uri.AbsoluteUri)+"/api/v1/$ResourceName")
    }

    Process
    {
        $apir = [K8sAPI]::GetApiInfo($urlr)
        switch ($DetailLevel) {
            "Regular" {$apir.items.metadata}
            "High" {$apir.items}
            "Full" {$apir}
        }
    }
}

<#
.SYNOPSIS
Produces an object of Kubernetes Pods.
.DESCRIPTION
Produces an object of Pods and their container(s) via proxied connection.
See Notes and Examples.
.PARAMETER Uri
URI that has been proxied via kubectl.
.INPUTS
URI that has been proxied via kubectl.
.OUTPUTS
pscustombobject SupSkiFun.Kubernetes.Pods.Info
.NOTES
1.  Command works both locally (Linux) and remotely (Linux or Windows).
2.  For this Advanced Function to work properly:
    a) Ensure that the API has been proxied:
        Start-Job -ScriptBlock {kubectl proxy --port 8888}
    b) Run the command, returning the information into a variable:
        $myVar = Get-K8sPod -Uri http://127.0.0.1:8888
3. If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.
4. For PowerShell 7, ensure the use of 127.0.0.1 instead of localhost.  Using localhost is far slower.
.EXAMPLE
Please Read:

Note: Any free port above 1024 can be used; if using a port different than 8888, substitute accordingly.
Note: If using microK8s it may be necessary to run 'microk8s kubectl' in place of 'kubectl'.

Before this Advanced Function will work, a proxy to the API must be configured.
    Start-Job -ScriptBlock {kubectl proxy --port 8888}

Once the proxy is established:
    $myVar = Get-K8sPod -Uri http://127.0.0.1:8888

Display all pods:
    $myVar

Drill into one pod's labels:
    ($myVar[0]).Labels

Drill into one pod's container(s):
    ($myVar[0]).Containers

Drill into one pod's container's Environment:
    ($myVar[0]).Containers[0].Environment

Drill into one pod's container's Image:
    ($myVar[0]).Containers[0].Image

Convert the entire object to JSON:
    $myVar | ConvertTo-Json -Depth 10
#>

Function Get-K8sPod
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

        $urlp = ($($Uri.AbsoluteUri)+$([K8sAPI]::urip))
    }

    Process
    {
        $apip = [K8sAPI]::GetApiInfo($urlp)
        foreach ($pod in $apip.items)
        {
            $lo = [K8sAPI]::MakePodObj($pod)
            $lo
        }
    }
}