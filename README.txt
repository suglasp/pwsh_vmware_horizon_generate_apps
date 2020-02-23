
Pieter De Ridder
Vmware Horizon 7 Powershell scripts to deploy Apps

Deploy or Delete VDI Farm APPS
------------------------------

In each script, you will first need to select the FARM name.
If there is only one FARM, the script will select that FARM automatically.

Start Powershell.
Notice : You will need PowerCLI installed, or copy all PowerCLI module folders in the "\Modules" local folder.

For TEST environment:
.\generate_vapps.ps1        : deploy apps defined in "generate_vapps.txt" to TEST
.\clean_vapps.ps1           : delete apps on TEST

For PROD environment:
.\generate_vapps.ps1 -prod  :  deploy apps defined in "generate_vapps.txt" to PROD
.\clean_vapps.ps1 -prod     :  delete apps on PROD
