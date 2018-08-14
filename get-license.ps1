function Get-NSXLicenseInfo {
    $licenseDictionary = @{}
    $nsxManagerLicenseLabelstemp = "CostUnit", "EditionKey", "LicenseKey", "Name", "Total"
    $nsxManagerLicenseLabels = @()

    #Getting License info fron vCenter 
    $ServiceInstance = Get-View ServiceInstance
    $LicenseManager = Get-View $ServiceInstance.Content.licenseManager
    $details = $LicenseManager.Licenses | where-object { $_.EditionKey -match 'nsx' }

    $tcount=1
    foreach ($eachdetail in $details){
        $nsxManagerLicenseLabelstemp | %{
            $newlable = [string]$_+$tcount
            $nsxManagerLicenseLabels += $newlable
            $licenseDictionary[$newlable]=[string]$($eachdetail.$_)
        }
        $tcount++
    }

    #Getting License info from NSX Mgr via API call
    $licenseResponse = Invoke-NsxRestMethod -URI "/api/2.0/services/licensing/capacityusage" -method get
    $licenseUsageInfo = $licenseResponse.featureCapacityUsageList.featureCapacityUsageInfo
    $licenseUsageInfo | %{
        $myfeature = $_.feature
        $_.capacityUsageInfo | %{
            [String]$newCapacityType = $myfeature+"-"+$($_.capacityType)
            $nsxManagerLicenseLabels += $newCapacityType
            $licenseDictionary[$myfeature+"-"+$($_.capacityType)] = $_.usageCount
        }
    }

    $licenseArray = $licenseDictionary, $nsxManagerLicenseLabels
    return $licenseArray
}
