This repository contains scripts i've written for automating driver management.

DocumentandExportDrivers.PS1 - This script exports a list of all drivers installed through Windows Update to a CSV, and exports all installed third party drivers to a folder.

ImportDriversToSCCM.ps1 - This script reads the name of a CSV file within a folder, and creates a new SCCM driver pack, category and driver folder using that name. It then imports all the drivers in the folder specified to SCCM, adds them to the driver pack, distributes it, and moves the drivers within the SCCM folder structure.
