
#If not logged in to Azure, start login...
if ($Null -eq (Get-AzContext).Account) {
    $AzureEnv = Get-AzEnvironment | Select-Object -Property Name  | 
    Out-GridView -Title "Choose your Azure environment.  NOTE: For Azure Commercial choose AzureCloud" -OutputMode Single
    Connect-AzAccount -Environment $AzureEnv.Name }


Write-Host "Import CSV..." -ForegroundColor Cyan

Function Get-FileNameDialog {
    Param (
        $InitialDirectory,
        [ValidateSet("CSV","TXT")]
        $FileType
    )

    [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.initialDirectory = $InitialDirectory
    If ($FileType -eq "CSV") {$OpenFileDialog.filter = "CSV files (*.csv)| *.csv| All files (*.*)| *.*"}
    ElseIf ($FileType -eq "TXT") {$OpenFileDialog.filter = "Text files (*.txt)| *.txt| All files (*.*)| *.*"}
    Else {$OpenFileDialog.filter = "CSV files (*.csv)| *.csv| Text files (*.txt)| *.txt| All files (*.*)| *.*"}
    $OpenFileDialog.ShowDialog() | Out-Null
    $File = $OpenFileDialog.filename
    Return $File
}

cls
Write-Host "Select CSV Input File Explorer PopUp to continue..." -ForegroundColor Yellow
Write-Host "NOTE: it could be behind the current window!" -ForegroundColor Yellow
$CSVPath = Get-FileNameDialog -FileType "CSV" -InitialDirectory "$((Get-ItemProperty .).FullName)\CsvFiltered"

If (!$CSVPath) {Write-Host "No Input CSV File!" -ForegroundColor Red ; Break}

$Nics = Import-Csv -path $CSVPath

Write-Host "Filtered Nics will appear in PopUp, Close PopUp to continue..." -ForegroundColor Yellow
$Nics | ogv -Wait -Title "Filtered Nics, close to continue..."

Write-Host "`nType ""BreakGlass"" to Clear DNS Setting ($($Nics.Count) Total), or Ctrl-C to Exit" -ForegroundColor Green
$HostInput = $Null
$HostInput = Read-Host "Final Answer" 
If ($HostInput -ne "BreakGlass" ) {
    Break
}

Write-Host "Start Nic DNS Clearing..." -ForegroundColor Cyan

$Nics | ForEach-Object { 
            If ((Get-AzContext).Subscription.Id -ne $_.SubscriptionID ) {Set-AzContext -SubscriptionID $_.SubscriptionID}
            Write-Host "Clearing DNS for $($_.Name) in Subscription $($_.SubscriptionID) " -ForegroundColor Cyan

            $Nic = Get-AzNetworkInterface -ResourceGroupName $_.ResourceGroupName -Name $_.Name
            $Nic.DnsSettings.DnsServers.Clear()
            $Nic | Set-AzNetworkInterface | Out-Null
}

Write-Host "Done!" -ForegroundColor Cyan
