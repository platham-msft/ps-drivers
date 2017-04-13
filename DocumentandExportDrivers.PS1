# Powershell Script to output a CSV containing a list of all the drivers installed through Windows Update
# and export all installed drivers to a folder (this will include drivers installed by other means too)
# This is a sample script, no warranty given or implied
# V0.2 - platham@microsoft.com - Changes - CSV goes into the OutputDir\Model directory

Param (
    [Parameter(Position=0,HelpMessage="Path to output the drivers and the CSV to e.g. C:\drivers")]
    [ValidateNotNullOrEmpty()]
    [string] $OutputDir = "c:\drivers"

)


# Get the Model information from WMI and store it in a variable
$Model = Get-WmiObject -Class Win32_ComputerSystem

# Flatten the variable so it just contains the manufacturer and model in a string
$Model = $Model.Manufacturer + "_" + $Model.Model

# Create a directory to output into
New-Item $OutputDir\$Model -ItemType Directory -ErrorAction SilentlyContinue

# Create a new update session
$UpdateSession = New-Object -ComObject Microsoft.Update.Session

# Invoke the update searcher method
$UpdateSearcher = $UpdateSession.CreateUpdateSearcher()

# Get the total number of update installations
$HistoryCount = $UpdateSearcher.GetTotalHistoryCount()

# Query the complete update history then pipe it into where object for filtering
$UpdateSearcher.QueryHistory(0,$HistoryCount) | Where-Object {

# Filters

$_.SupportUrl -eq "http://support.microsoft.com/select/?target=hub" -and # Match the SupportURL all drivers seem to have
$_.Operation -eq "1" -and  # Only show Install operations
($_.ResultCode -eq "2" -or $_.ResultCode -eq "3")} |` # Only show installs that succeeded, pipe to select object

# Select the Title, the date of installation, and convert the resultcode to human readable
Select-Object Title, Date, @{Name="Status"; Expression=
  {
    Switch($_.ResultCode)
    {
        2 {"Succeeded" }; 
        3 {"Succeeded With Errors" }
    }
  }

# End the Expression, pipe to sort object to show newest installs at the top, pipe to CSV
 } | Sort-Object -Descending: $true -Property Date | Export-CSV "$OutputDir\$Model\$Model.CSV" -NoTypeInformation

# Export all installed third party drivers into the directory we created above
Export-WindowsDriver -Online -Destination $OutputDir\$Model