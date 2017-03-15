# e-Cube an NSX-v Operationalization project

## Prerequisite:
* VMware PowerCLI [https://www.vmware.com/support/developer/PowerCLI/]
* Microsoft Excel installed on the local system [https://products.office.com/en-au/excel]
* GIT (optional) [https://git-scm.com/]
* MS VISIO (optional - some feature wont work if not installed) [https://www.microsoft.com/en-us/evalcenter/evaluate-visio-professional-2016]
* PowerShell's Testing Framework Module name: Pester [http://www.powershellmagazine.com/2014/03/12/get-started-with-pester-powershell-unit-testing-framework/]
  (Unzip pester folder at C:\Users\****\Documents\WindowsPowerShell\Modules)
* PowerShell's SSH Module name: Posh-SSH [https://github.com/darkoperator/Posh-SSH]
  Note: By running this command: iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")
* Access to NSX Manager API with privileges
* Access to vSphere Web Client and Privileges (Read)

## Notes:
* Run the e-Cube.ps1 in PowerShell [tested on VMware PowerCLI 6.5 Release 1]
* When in e-Cube.ps1:
    * To get the list of available commands type 'help'
    * To exit type 'exit' or '0'
* Install VMware PowerNSX by selecting option #1
* Connect with NSX Manager and vCenter by selecting option #2
 
### Contact Info: cpuneet@vmware.com