#If not logged in to Azure, start login

Write-Host "`nChecking Azure Login..." -ForegroundColor Cyan
try {
    Get-AzureRMContext
}
catch  {
    if ($_ -like "*Connect-AzureRmAccount to login*")
{
    Write-Host "`nYou are not logged in to AzureGovCloud... I will prompt you." -ForegroundColor Yellow
    Login-AzureRmAccount -EnvironmentName AzureUSGovernment
    }
}

Write-Host "`nChoose Subscriptions in PopUp..." -ForegroundColor Cyan

$SubSelection = Get-AzureRmSubscription | Out-GridView -Title "Select a Subscription" -OutputMode Multiple

Write-Host "`nGathering all Nic info, this could take a few..." -ForegroundColor Cyan

$Nics_All = $SubSelection | 
ForEach-Object { 
    $_ | Set-AzContext | 
        ForEach-Object {     
            Get-AzNetworkInterface
        }
} 

Write-Host "`nUpdate Nics with additional info..." -ForegroundColor Cyan

$Nics_Updated  =  $Nics_All |
    ForEach-Object { $_ |
        Select-Object *,
            @{N='SubscriptionID';E={
                $_.Id.tostring().split('/')[2] 
                }
            },
            @{N='Subscription';E={
                  $_.Id.tostring().split('/')[2] | ForEach-Object { (Get-AzSubscription -SubscriptionId $_).Name } 
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

Write-Host "`nFlatten, filter, and Sort Nic info..." -ForegroundColor Cyan

$Nics_Filtered =  $Nics_Updated | 
    Select-Object -Property Subscription,SubscriptionID,Location,ResourceGroupName,Owner,Name,VNetSub,VNetRG,VNet,Subnet,Primary,NSG,MacAddress,DnsServers,PrivateIp,PrivateIPs |
    Sort-Object Subscription,Location,ResourceGroupName,Owner,Name

# $Nics_Filtered | ogv


$NowStr = Get-Date -Format yyyy-MM-ddTHH.mm.fff
$FileName = ".\CsvExport\$($NowStr)_Nics_All.csv"

Write-Host "`nExport to Csv at $($FileName) ..." -ForegroundColor Cyan

$Nics_Filtered | Export-Csv -Path $FileName -NoTypeInformation

Write-Host "`nDone!" -ForegroundColor Cyan
