class K8sAPI
{
    static $uric = 'api/v1/'
    static $uria = 'apis/'
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

    static [psobject] GetResourceInfo ( [string] $url )
    {
        $resq = Invoke-RestMethod -Method Get -Uri $url
        $resi = $resq.resources.Where({$_.name -notmatch "/"})
        return $resi
    }

    static [pscustomobject] MakeContainerObj ([psobject] $cont)
    {
        $arr = [System.Collections.ArrayList]::new()
        foreach ($c in $cont)
        {
            $lo = [PSCustomObject]@{
                Name = $c.name
                Image = $c.image
                VolumeMounts = $c.VolumeMounts
                ImagePullPolicy = $c.ImagePullPolicy
                Environment = $c.env
            }
            $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.Kubernetes.Container.Info')
            $arr.add($lo)
        }
        return $arr
    }

    static [pscustomobject] MakeNameSpaceObj ([psobject] $ns)
    {
        $lo = [PSCustomObject]@{
            Name = $ns.metadata.name
            Creation = $ns.metadata.creationTimestamp
            SelfLink = $ns.metadata.selfLink
            Status = $ns.status.phase
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.Kubernetes.NameSpace.Info')
        return $lo
    }

    static [pscustomobject] MakeObj (
            [string] $nom ,
            [string] $grv ,
            [psobject] $res
        )
    {
        $lo = [PSCustomObject]@{
            GroupName = "core"
            GroupVersion = $grv
            Version = $grv
            PreferredVersion = $true
            ResourceName = $res.name
            ResourceKind = $res.kind
            ShortName = $res.shortNames
            NameSpaced = $res.namespaced
            Verbs = $res.verbs
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.Kubernetes.API.Info')
        return $lo
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
            PreferredVersion = if ($prv -eq $gvv) {$true} else {$false}
            ResourceName = $res.name
            ResourceKind = $res.kind
            ShortName = $res.shortNames
            NameSpaced = $res.namespaced
            Verbs = $res.verbs
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.Kubernetes.API.Info')
        return $lo
    }

    static [pscustomobject] MakePodObj ([psobject] $pod)
    {
        $cs = [K8sAPI]::MakeContainerObj($pod.spec.containers)
        $lo = [PSCustomObject]@{
            Name = $pod.metadata.name
            NameSpace = $pod.metadata.namespace
            NodeName = $pod.spec.nodeName
            Status = $pod.status.phase
            Creation = $pod.metadata.creationTimestamp
            SelfLink = $pod.metadata.selfLink
            Labels = $pod.metadata.Labels
            Containers = $cs
        }
        $lo.PSObject.TypeNames.Insert(0,'SupSkiFun.Kubernetes.Pod.Info')
        return $lo
    }


}