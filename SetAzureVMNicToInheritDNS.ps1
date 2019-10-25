<#
.AURHOR
    Ernest.Oshokoya@va.gov

.DESCRIPTION
    Script gets VM information for output validation,
    reads the content of a CSV file for the NIC Card information and clears the DNS enteries thus enabling the NICs to inherit form the VNET.
    
.PARAMETER
    Path - Path to the NIC.csv file containing NICName, VMName, Subscription & RGName
    NetworkCSV - Array to hold the contents of the NICS.csv file
#>

cls

<#
Sample data - create your own nics.csv with the following info and set the $path:

NicName,VMName,Subscription,RGName
demo-nic,demo-vm,mysubscription,demo-rg
poc-nic,poc-vm,mysubscription,poc-rg
#>

#Import network CSV 
$Path = "C:\Temp\file - Copy.csv"
$NetworkCSV = @()
$NetworkCSV = Import-Csv -Path $Path

#Get current subscription info
#Check Azure Login
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

foreach ($Data in $NetworkCSV)
{
    $Infos += "$($Data.NicName),$($Data.VMName),$($Data.Subscription),$($Data.RGName)"

    $RG = "$($Data.RGName)"
    $VM = "$($Data.VMName)"
    $NIC = "$($Data.NicName)"
    $Sub = "$($Data.Subscription)"

    foreach ($info in $Infos) 
    {
    # For Unattached NICs
        if (!$RG)
        {
            Write-Host "`n$Nic is missing a Resource Group..." -ForegroundColor Yellow
        }   
        else 
        {
            Write-Host "`nSelecting subscription '$sub'" -ForegroundColor Green
            Select-AzureRmSubscription -Subscription $sub
            
            Write-Host "`nGetting Virtual Machine '$VM' information..." -ForegroundColor Green
            Get-AzureRmVM -ResourceGroupName $RG -Name $VM

            try {
                Write-Host "`nConfiguring DNS Enteries for '$VM'" -ForegroundColor Green
                $setting = Get-AzureRmNetworkInterface -ResourceGroupName $RG -Name $NIC
                $setting.DnsSettings.DnsServers #Prints current DNS enteries
                $setting.DnsSettings.DnsServers.Clear() # Clears out the current DNS enteries and inherits from VNET
                $setting | Set-AzureRmNetworkInterface
            }
            catch {
                Write-Host "`nFailed to apply DNS rules for $VM with nic: $NIC" >> failed.txt
                continue
            } 
        }
    }
}

Write-Host "`nALL DONE..."
