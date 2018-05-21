$ServiceInstance = Get-View ServiceInstance
$LicenseManager = Get-View $ServiceInstance.Content.licenseManager
$detail= $LicenseManager.Licenses | where-object { $_.EditionKey -match 'nsx' }
return $detail