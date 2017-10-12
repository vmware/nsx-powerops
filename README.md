==================================================================
# NSX PowerOps - An NSX-v Operationalization Project #
==================================================================

## Prerequisite:

Required Pre-Requisites:

* PowerShell 5.0

* VMware PowerCLI 6.5.2 [https://www.vmware.com/support/developer/PowerCLI/]

* Microsoft Excel installed on the local system (tested on Office 365) [https://products.office.com/en-us/excel]

* Access to NSX Manager API with privileges (min Read)

* Access to vSphere Web Client and Privileges (min Read)

* VMware PowerNSX 3.0.1012 (NSX PowerOps automatically install this module)

* Pester (NSX PowerOps automatically install this module)

        Pester - PowerShell's Testing Framework Module - Manual Install Steps:
        [http://www.powershellmagazine.com/2014/03/12/get-started-with-pester-powershell-unit-testing-framework/]
        Highlevel steps:
            * Right click on the zip file and hit properties. Click Unblock. Do it before unzipping to save time.
            * Extract the file and put the folder under: [C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\Pester] such that all the files are under folder Pester in the Modules directory.
            * Run PowerCLI as Administrator and execute following commands
                * Get-Module -ListAvailable -Name Pester
                * Import-Module Pester
                * Get-Module -Name Pester | Select -ExpandProperty ExportedCommands

* Posh-SSH (NSX PowerOps automatically install this module)

        Posh-SSH - PowerShell's SSH Module - Manual Install Steps:
        * Option 1:
            * Run PowerCLI as Administrator and execute: iex (New-Object Net.WebClient).DownloadString("https://gist.github.com/darkoperator/6152630/raw/c67de4f7cd780ba367cccbc2593f38d18ce6df89/instposhsshdev")

    	* Option 2:
        	* Download the Module [https://github.com/darkoperator/Posh-SSH/archive/master.zip]
        	* Extract the files under [C:\Program Files (x86)\VMware\Infrastructure\PowerCLI\Modules\Posh-SSH] such that all the files are under folder Posh-SSH in the Modules directory.
        	* Run PowerCLI as Administrator and execute following commands
        		* Get-Module -ListAvailable -Name Posh-SSH
        		* Import-Module Posh-SSH
        		* Get-Module -Name Posh-SSH | Select -ExpandProperty ExportedCommands


Optional Pre-Requisites:

* MS VISIO (optional - some feature wont work if not installed) [https://www.microsoft.com/en-us/evalcenter/evaluate-visio-professional-2016]
* GIT (optional) [https://git-scm.com/]

## Download via git:
    git clone https://gitlab.com/VMware-NSBU-SAS/NSX-PowerOps.git
    

## Notes:
* For PowerCLI to work correctly: 'Set-ExecutionPolicy RemoteSigned' in powercli
* Run the nsx-PowerOps.ps1 in PowerShell [tested on VMware PowerCLI 6.5.2]
* When in nsx-PowerOps.ps1:
    * To get the list of available commands type 'help'
    * To exit type 'exit' or '0'
* Install NSX PowerOps depedency (PowerNSX, Pester, Posh-SSH) by selecting option # 1
* Connect with NSX Manager and vCenter by selecting option # 2
 
### Contact Info: cpuneet@vmware.com (Puneet Chawla) and halam@vmware.com (Hammad Alam)