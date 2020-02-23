
#
# Pieter De Ridder
# VMware Horizon 7 : Script to delete Horizon7 Apps published mostly to a RDS farm on top of VDI
#
# CLI parameters:
# "-prod" : delete apps on production ( default is test)
#


# global vars
$global:WorkFolder    = $PSScriptRoot                           
$global:DomainName    = ($env:USERDNSDOMAIN).ToLowerInvariant()  
$global:AddonModules  = "$($global:WorkFolder)\Modules"
$global:IconFiles     = "$($global:WorkFolder)\IconFiles"
$global:DeployFile     = "$($global:WorkFolder)\generate_vapps.txt"


# VMWare Horizon Connection servers
$HVServerTestA = "horizon_test_con_1.$($global:DomainName)"
$HVServerTestB = "horizon_test_con_2.$($global:DomainName)"

$HVServerProdA = "horizon_prod_con_1.$($global:DomainName)"
$HVServerProdB = "horizon_prod_con_1.$($global:DomainName)"


#
# Function : BailOut-Script
# Hard terminates script
#
Function BailOut-Script
{
    Write-Log -LogMsg ""
    Write-Log -LogMsg "-- BAIL OUT"
    Exit(11)
}

#
# Function : End-Script
# Prints "-- END" and leaves further instructions
#
Function End-Script
{
    Write-Log -LogMsg ""
    Write-Log -LogMsg "-- END"
}



Function Main {

    Param (
        $Arguments
    )

    Write-Host ""
    Write-Host " --- CLEANING VDI APPLICATIONS ---"
    Write-Host ""

    # target PROD env?
    [bool]$isProd = $false

    # logic for cmdline arguments
    If ($Arguments) {
        for($i = 0; $i -lt $Arguments.Length; $i++) {
            #Write-Host "DEBUG : Arg $($i.ToString()) is $($args[$i])"

            # default, a PWSH Switch statement on a String is always case insenstive
            Switch ($Arguments[$i]) {
                "-prod" {                    
                    $isProd = $true
                }

            }                        
        }
    }


    # set custom modules path
    If (-not ($env:PSModulePath.Contains($global:AddonModules))) {
        $env:PSModulePath += ";" + $global:AddonModules
    }


    # load vmware powercli modules
    If (-not (Get-Module -Name VMware.PowerCLI)) {
        Import-Module VMWare.PowerCLI
    }

    If (-not (Get-Module -Name VMware.VimAutomation.HorizonView)) {
        Import-Module VMware.VimAutomation.HorizonView
    }
    

    # load powercli examples module
    If (-not (Get-Module -Name VMware.Hv.Helper)) {
        # get all cmdlets : $ > (Get-Module VMware.Hv.Helper).ExportedCommands
        Import-Module VMware.Hv.Helper
    }


    If ($isProd) {
        Write-Host "-> Target Env : PROD"
    } else {
        Write-Host "-> Target Env : TEST"
    }


    # connect to Connection server on test env and fetch apps
    Write-Host "I need Horizon Admin credentials..."
    $oAdminCred = Get-Credential -Message "Credentials..." -UserName "$($env:USERDOMAIN.ToLowerInvariant())\$($env:USERNAME)t1adm"


    # set Vmware Horizon Connection server ENV
    $sHRServerName = ""
    
    If ($isProd) {
        # set one of PROD connection servers
        If (Test-NetConnection -ComputerName $HVServerProdA -Port 443) {
            $sHRServerName = $HVServerProdA
        } else {
            $sHRServerName = $HVServerProdB
        }
    } Else {
        # set one of TEST connection servers
        If (Test-NetConnection -ComputerName $HVServerTestA -Port 443) {
            $sHRServerName = $HVServerTestA
        } else {
            $sHRServerName = $HVServerTestB
        }
    }

    Write-Host "Connecting $($sHRServerName)..."
    $oHVServer = Connect-HVServer -Server $sHRServerName -Credential $oAdminCred
    

    If ($oHVServer) {
        If ($oHVServer.IsConnected) {
            Write-Host "Connected."
            #$hvTestApps = Get-HVApplication -HvServer $oHVServer
            #$hvTestApps
            
            # Get FARM(S)
            Write-Host ""
            Write-Host "Available farms:"
            $arrFarms = @((Get-HVFarm).Data.Name)

            If ($arrFarms.Length -gt 0) {
                $arrFarms

                Write-Host ""
                [string]$sFarmName = ""

                # Set FARM Name
                If ($arrFarms.Length -eq 1) {
                    $sFarmName = $arrFarms[0]
                } else {
                    [string]$sFarmName = Read-Host -Prompt "Enter name of farm"
                }

                Write-Host "-> Set farm : $($sFarmName.Trim())"
                Write-Host ""

                # get FARM ID (Some kind of hashed name)
                $arrFarms = @(Get-HVFarm)
                $sFarmID = ""

                ForEach($oFarm in $arrFarms) {
                    If ($oFarm.Data.Name -like $sFarmName) {
                        $sFarmID = $oFarm.Id
                    }                
                }


                # delete apps for selected FARM
                If ($sFarmID) {
             
                    Write-Host "Getting Applications for Farm $($sFarmName.Trim())..."
                    $arrApps = Get-HVApplication -HvServer $oHVServer
                    
                    Read-Host -Prompt "Press enter to delete applications... "

                    # delete apps for Farm
                    ForEach($oApp in $arrApps) {
                        If ($oApp.ExecutionData.Farm -eq $sFarmID) {
                            Remove-HVApplication -ApplicationName $oApp.Data.Name -Confirm:$false
                        }
                    }

                } else {
                    Write-Warning "[!] Farm ID fetch failed."
                    Disconnect-HVServer -Server $oHVServer  -Confirm:$false -Force
                    BailOut-Script
                }

            }
                               
            Disconnect-HVServer -Server $oHVServer -Confirm:$false -Force
            Write-Host "Disconnected $($sHRServerName)."
        }
    } else {
        Write-Warning "[!] Connection failed to $($sHRServerName)."
        BailOut-Script
    }

}



#--- CALL MAIN ----
Main -Arguments $args

