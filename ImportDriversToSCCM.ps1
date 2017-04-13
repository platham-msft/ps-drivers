# Script to import all drivers in a folder to SCCM, tag them with a category, put them in a driver pack, distribute the driver pack to a distribution point group
# There should be a CSV in the root of the folder named Manufacturer_Model.CSV (e.g. Microsoft_SurfacePro4.CSV ) from which we take the name
# V0.2 platham@microsoft.com - No warranty given or implied
# Changes - Moved the get cm site to after modules loaded, added last 3 actions to move drivers into a folder in the console

Param (
    [Parameter(Position=0,HelpMessage="The directory with all the drivers in you want to import, it should have a CSV in the root called Manufacturer_Model.CSV")]
    [ValidateNotNullOrEmpty()]
    [string] $GoldFolder = "\\sccm01\e$\Source\Drivers\home_pc",

    [Parameter(Position=1,HelpMessage="The directory in which to store driver packages")]
    [ValidateNotNullOrEmpty()]
    [string] $PkgSrcFolder = "\\sccm01\PackageSource$\Drivers",

    [Parameter(Position=2,HelpMessage="The name of the distribution point group you want to distribute to")]
    [ValidateNotNullOrEmpty()]
    [string] $Dpg = "Datacenter DPs"

)

Set-Location C:\

# This will get the name of the CSV file in the root of the folder so we can use it to name things
$Model = (Get-ChildItem $GoldFolder\*.csv).BaseName

# Import the ConfigMgr Powershell Module
Import-Module "E:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1"

# This will get the name of the ConfigMgr Site for us
$CMSite=”$(Get-PSDrive –PSProvider CMSite)`:”

# Create a folder for the driver package
New-Item -ItemType Directory -Path $PkgSrcFolder -Name $Model

# Change our context to the CM Site
Set-Location $CMSite

# Create a new category named after our pc model
New-CMCategory -CategoryType DriverCategories -Name $Model

# Store it in a variable. Split on two lines in case category exists we don't want script to fall over
$DrvCategory = Get-CMCategory -Name $Model

# Create the driver package
New-CMDriverPackage -Name $Model -Path $PkgSrcFolder\$Model

# Store the package in a variable. Again this is on another line to stop the script falling over if it already exists
$DrvPackage = Get-CMDriverPackage -Name $Model

# Import all the drivers in the folder, tag them with the category and add them to the driver package
Import-CMDriver -UncFileLocation $GoldFolder -ImportFolder -ImportDuplicateDriverOption AppendCategory -AdministrativeCategory $DrvCategory -EnableAndAllowInstall $true -DriverPackage $DrvPackage

# Distribute the content to distribution points
Start-CMContentDistribution -DriverPackageName $Model -DistributionPointGroupName $Dpg

# Create a driver folder for organisation in the console
New-Item -Path $CMSite\Driver -Name $Model -ErrorAction SilentlyContinue

# Get the list of drivers to move
$Driverlist = Get-CMDriver -DriverPackageName $Model

# Move the drivers into the folder
Move-CMObject -FolderPath $CMSite\Driver\$Model -InputObject $Driverlist