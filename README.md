======================================================
# NSX PowerOps - An NSX-v Operationalization Project #
======================================================

## Prerequisite:

Required Pre-Requisites:

* VMware PowerCLI [https://www.vmware.com/support/developer/PowerCLI/]

* Microsoft Excel installed on the local system [https://products.office.com/en-us/excel]

* PowerShell's Testing Framework Module name: Pester [http://www.powershellmagazine.com/2014/03/12/get-started-with-pester-powershell-unit-testing-framework/]
	Highlevel steps:
	* Right click on the zip file and hit properties. Click Unblock. Do it before unzipping to save time.
	* Extract the file and put the folder under: [C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\Pester] such that all the files are under folder Pester in the Modules directory.
	* Run PowerCLI as Administrator and execute following commands
		* Get-Module -ListAvailable -Name Pester
		* Import-Module Pester
		* Get-Module -Name Pester | Select -ExpandProperty ExportedCommands

* PowerShell's SSH Module name: Posh-SSH [https://github.com/darkoperator/Posh-SSH]

Option 1 (Automated Install):  
	* Run PowerCLI as Administrator and execute: iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")

Option 2 (Manual Steps):
	* Download the Module [https://github.com/darkoperator/Posh-SSH/archive/master.zip]
	* Extract the files under [C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\Pester] such that all the files are under folder Posh-SSH in the Modules directory.
	* Run PowerCLI as Administrator and execute following commands
		* Get-Module -ListAvailable -Name Posh-SSH
		* Import-Module Posh-SSH
		* Get-Module -Name Posh-SSH | Select -ExpandProperty ExportedCommands

		* Access to NSX Manager API with privileges

* Access to vSphere Web Client and Privileges (Read)

Optional Pre-Requisites:

* GIT (optional) [https://git-scm.com/]
* MS VISIO (optional - some feature wont work if not installed) [https://www.microsoft.com/en-us/evalcenter/evaluate-visio-professional-2016]


## Notes:
* For PowerCLI to work correctly: 'Set-ExecutionPolicy RemoteSigned' in powercli
* Run the e-Cube.ps1 in PowerShell [tested on VMware PowerCLI 6.5 Release 1]
* When in e-Cube.ps1:
    * To get the list of available commands type 'help'
    * To exit type 'exit' or '0'
* Install VMware PowerNSX by selecting option #1
* Connect with NSX Manager and vCenter by selecting option #2
 
### Contact Info: cpuneet@vmware.com