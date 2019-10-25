Login-AzureRMAccount -EnvironmentName AzureUSGovernment
$i = 0
$csvFilename = "c:\temp\output.csv"   #or replace with a hard coded path like c:\temp

$subscriptions = get-azurermsubscription
$csv = @()
foreach($sub in $subscriptions)
{ 
    Select-AzureRmSubscription -SubscriptionName $sub
   
    $Output = Get-AzureRMVirtualNetwork | Where-Object {($_.Name -notlike "*gateway*" -and $_.Name -notlike "*gw*")}
    foreach($o in $Output)
    {
   
        $object = new-object PSObject;   #create new object for this iteration
        $object | add-member NoteProperty Name $o.Name  #add name
        $object | Add-Member Noteproperty RG $o.ResourceGroupName
        $DNS = (convertfrom-json -inputobject $o.DhcpOptionsText)
        $DNS = $Dns.DnsServers
        $i = 1
        foreach($dhcpobj in $DNS)     #loop through and add dnsservers
        {           
            $object | add-member NoteProperty "DNSServer$i" $dhcpobj #.DnsServers  #each column would be named by number (1,2,3,4...)
            #$object | Add-Member NoteProperty "RG$i" $RG
            $i++
        }
        $i = 0
        #output ojbect-- row -- to CSV appending     
        $object |export-csv "C:\Temp\file.txt" -NoTypeInformation -Append -Force 
    }
}
