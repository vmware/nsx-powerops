function Get-NSXEnvSummary($nsxManagementLabels, $nsxManagerSummary) {
    $licenseDictionary = @{}

    write-host $nsxManagerSummary.versioninfo
    $nsxManagementLabels | %{
        #$nsxManagementLabels = "NSX Manager Version", "Version of vCenter", "Total NSX Controllers deployed", "Total Cluster(s) prepared for NSX", "Total Host(s) managed by NSX"
        if ($_ -eq "NSX Manager Version") {
            $licenseDictionary[$_] = $nsxManagerSummary.versioninfo
        }
        elseif ($_ -eq "Total NSX Controllers deployed") {
            $c = Get-NsxController
            $licenseDictionary[$_] = $c.name.count
        }
        elseif ($_ -eq "Total Cluster(s) prepared for NSX") {
            $c = Get-Cluster
            $licenseDictionary[$_] = $c.count
        }
        elseif ($_ -eq "Total Host(s) managed by NSX") {
            $h = Get-Host
            $licenseDictionary[$_] = $h.count
        }
    }

    $licenseArray = $licenseDictionary, $nsxManagementLabels
    return $licenseArray
}

function Get-NSXSecuritySummary($nsxSecurityLables) {
    $licenseDictionary = @{}

    $nsxSecurityLables | %{
        #$nsxSecurityLables = "Total FireWall (DFW) Rules", "Total Service Composer Policies", "Total Security Groups", "Total Security Tags"
        if ($_ -eq "Total FireWall (DFW) Rules") {
            $f = Get-NsxFirewallRule
            $licenseDictionary[$_] = $f.count
        }
        elseif ($_ -eq "Total Security Groups") {
            $sg = Get-NsxSecurityGroup
            $licenseDictionary[$_] = $sg.name.count
        }
        elseif ($_ -eq "Total Security Tags") {
            $st = Get-NsxSecurityTag
            $licenseDictionary[$_] = $st.count
        }
    }

    $licenseArray = $licenseDictionary, $nsxSecurityLables
    return $licenseArray
}

function Get-NSXRASSummary($nsxRASLables) {
    $licenseDictionary = @{}

    $nsxRASLables | %{
        #$nsxNASLables = "Total Edges", "Total Edges with BGP enabled", "Total Edges with OSPF enabled", "Total Edges with SSL-VPN enabled", "Total Edges with L2VPN enabled", "Total DLRs", "Total DLRs with L2 Bridging enabled", "Total UDLRs", "Total Edges with LB", "Total VIPs", "Total Pool Members", "Total Logical Switches"
        if ($_ -eq "Total Edges") {
            $edge = Get-NsxEdge
            $licenseDictionary[$_] = $edge.count
        }
        elseif ($_ -eq "Total DLRs") {
            $dlr = Get-NsxLogicalRouter
            $licenseDictionary[$_] = $dlr.count
        }
        elseif ($_ -eq "Total Logical Switches") {
            $ls = Get-NsxLogicalSwitch
            $licenseDictionary[$_] = $ls.count
        }
    }

    $licenseArray = $licenseDictionary, $nsxRASLables
    return $licenseArray
}