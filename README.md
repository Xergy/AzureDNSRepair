# AzureDNSRepair
Scripts query and set selected Azure VM Nics to Inherit DNS Settings from Subnet.

## More Information...

Repo contains several important files:

### CreateAzureVMNicsCSV.ps1

- Used to create ```.csv``` file ultimately consumed by ```SetAzureVMNicsToInheritDNSFromSubnet.ps1```.
- Files is stored in ```.\CsvExport```
- The output file is intended to be reviewed and filtered by a human.  Please place resulting manually filtered ```.csv``` files in the ```.\CsvFiltered```  folder.

### SetAzureVMNicsToInheritDNSFromSubnet.ps1

- Prompts for input Csv files in ```.\CsvFiltered```  
- Once input file is received, script sets selected VMs to inherit DNS for the Azure Portal Subnet.

## Know Issues and Caveats

- Script is intended to be run with VScode in the root of the AzureDNSRepair Folder