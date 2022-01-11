class K8sAPI
{
    static $uric = '/api/v1/'
    static $uria = '/apis/'
    static $urip = '/api/v1/pods'
    static $urin = '/api/v1/namespaces/'
    static $mesg = "Terminating.  Non-valid URL detected.  Submitted URL:  "

    static [boolean] CheckURI ([uri] $uri)
    {
        return ([uri] $uri).IsAbsoluteUri
    }

    static [psobject] GetApiInfo ( [string] $mainurl )
    {
        $mainurl
        $apis =  Invoke-RestMethod -Method Get -Uri $mainurl
        return $apis
    }
}

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