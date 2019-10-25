
#If not logged in to Azure, start login...
if ($Null -eq (Get-AzContext).Account) {
    $AzureEnv = Get-AzEnvironment | Select-Object -Property Name  | 
    Out-GridView -Title "Choose your Azure environment.  NOTE: For Azure Commercial choose AzureCloud" -OutputMode Single
    Connect-AzAccount -Environment $AzureEnv.Name }

cls
Write-Host "Choose Subscriptions in PopUp..." -ForegroundColor Cyan

$SubSelection = Get-AzSubscription | Out-GridView -Title "Select a Subscription" -OutputMode Multiple

Write-Host "Gathering all Nic info, this could take a few..." -ForegroundColor Cyan

$Nics_All = $SubSelection | 
ForEach-Object { 
    $_ | Set-AzContext | 
        ForEach-Object {     
            Get-AzNetworkInterface
        }
} 

Write-Host "Update Nics with additional info..." -ForegroundColor Cyan

$Nics_Updated  =  $Nics_All |
    ForEach-Object { $_ |
        Select-Object *,
            @{N='SubscriptionID';E={
                $_.Id.tostring().split('/')[2] 
                }
            },
            @{N='Subscription';E={
                  $_.Id.tostring().split('/')[2] | ForEach-Object {  
                        $CurrentSub = $_  
                        $SubSelection | Where-Object {$_.SubscriptionID -eq $CurrentSub } | ForEach-Object {
                            $_.Name
                        }
                  }  
                }
            },                
            @{N='PrivateIp';E={
                $_.IpConfigurations[0].PrivateIpAddress
                }
            },
            @{N='VNetSubID';E={
                $_.IpConfigurations[0].Subnet.Id.tostring().split('/')[2]
                }
            },
            @{N='VNetRG';E={
                $_.IpConfigurations[0].Subnet.Id.tostring().split('/')[4]
                }
            },
            @{N='VNet';E={
                $_.IpConfigurations[0].Subnet.Id.tostring().split('/')[8]
                }
            },
            @{N='Subnet';E={
                $_.IpConfigurations[0].Subnet.Id.tostring().split('/')[10]
                }
            },
            @{N='NSG';E={
                $_.NetworkSecurityGroup.id.tostring().substring($_.NetworkSecurityGroup.id.tostring().lastindexof('/')+1)
                }
            },
            @{N='Owner';E={
                $_.VirtualMachine.Id.tostring().substring($_.VirtualMachine.Id.tostring().lastindexof('/')+1)
                }
            },
            @{N='PrivateIPs';E={
                ($_.IpConfigurations.PrivateIpAddress) -join " "  
                }
            },
            @{N='DnsServers';E={
                ($_.DnsSettings.DnsServers) -join " "  
                }
            }
    }

# $Nics_Updated | ogv

Write-Host "Flatten, filter, and Sort Nic info..." -ForegroundColor Cyan

$Nics_Filtered =  $Nics_Updated | 
    Select-Object -Property Subscription,SubscriptionID,Location,ResourceGroupName,Owner,Name,VNetSub,VNetRG,VNet,Subnet,Primary,NSG,MacAddress,DnsServers,PrivateIp,PrivateIPs |
    Sort-Object Subscription,Location,ResourceGroupName,Owner,Name

# $Nics_Filtered | ogv


$NowStr = Get-Date -Format yyyy-MM-ddTHH.mm.fff
$FileName = ".\CsvExport\$($NowStr)_Nics_All.csv"

Write-Host "Export to Csv at $($FileName) ..." -ForegroundColor Cyan

$Nics_Filtered | Export-Csv -Path $FileName -NoTypeInformation

Write-Host "Done!" -ForegroundColor Cyan
