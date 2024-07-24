<#
Output Format CSV as follows:
"C:\path\to\file.ext",MD5HashHere
#>

#UNCOMMENT THIS LINE AND LINE 103 IF YOU WANT TO CALL AS SCRIPT
#LEAVE THEM TO JUST IMPORT THE CMDLET
#param([string]$outpath)

function Get-ServiceKeyHashes {
<#
.SYNOPSIS
    Gathers a list of services that are set up in the HKLM:\SYSTEM\Current
    ControlSet\Services key and takes the MD5 hash of each file, writes to file

.DESCRIPTION
    Get-ServiceKeyHashes is a function that gathers a list of services from
    the services key, hashes their ImagePath arguments, and writes the results to file
    or STDOUT in CSV format.

.PARAMETER Outfile
    The location to write the results to. If blank, outputs to STDOUT

.EXAMPLE
     Get-ServiceKeyHashes -Outfile "C:\users\myuserfolder\desktop\servicehashreport.csv"

.EXAMPLE
     Get-ServiceKeyHashes

.INPUTS
    String

.OUTPUTS
    CSV

.NOTES
    Author:  Christopher Dondzil
    Github: https://github.com/CreepChryan
    Last Updated: 7/23/2024

#>
param([string]$Outfile)
$svcBlocc = Get-ItemProperty -Path HKLM:\SYSTEM\CurrentControlSet\Services\* | Select-Object ImagePath
#Get all services in the reg key, pare down the data to just the exe/sys/dll/etc's feild
#Data is received in a polluted format, some quoted, some not, some absolute paths, some including env vars. Use RE to cut off all the CLI args and quotes first
$svcBlocc = ($svcBlocc | forEach {
    if ($_.ImagePath -ne $null) {
    if ($_.ImagePath[0] -eq '"') {$_.ImagePath -replace '"(([^"]+))".*','$1'}
    else {$_.ImagePath -replace '^(([A-Za-z]:)?(\\?(\w|\.)+\\)+\w+\.(\w|\.)+(\s|$))','$1'}
    }
})
$svcBlocc = ($svcBlocc | Select-Object -Unique)
#mostly deduped, need to handle inconsistencies in formatting now. Joyus.
$svcBlocc = ($svcBlocc | foreach {
    #if its not already in drive letter : path format we have to mess with it (Does not start with C:\ or D:\
    if ( -not ($_[0] -match '[A-Za-z]' -and $_[1] -eq ":" -and $_[2] -eq "\")) {
        #if it mentions system root envar just replace it with the actual value
        if ($_ -match '^\\?[Ss][Yy][Ss][Tt][Ee][Mm][Rr][Oo][Oo][Tt]\\') {
            $_ -replace '^\\?[Ss][Yy][Ss][Tt][Ee][Mm][Rr][Oo][Oo][Tt]',$env:SystemRoot
        }
        #if it goes into system32 automatically append the extra data from systemroot so it's actually functional
        elseif ($_ -match '^\\?[Ss][Yy][Ss][Tt][Ee][Mm]32\\') {
            $_ -replace '^\\?[Ss][Yy][Ss][Tt][Ee][Mm]32',([string]$env:SystemRoot + "\system32")
        }
        elseif ($_ -match '^\\?[Dd][Rr][Ii][Vv][Ee][Rr][Ss]\\') {
            $_ -replace '^\\?[Ss][Yy][Ss][Tt][Ee][Mm]32',([string]$env:SystemRoot + "\system32")
        }
    }
})
#data standardized, each line in svcBlocc is an absolute path to a file in need of hash verification.
#first clean up any straggler duplicates remaining because data standardization is a myth.
$svcBlocc = ($svcBlocc | sort -Unique)
<#
data storage structure:
$final[i]
    nested hashtable:
        .path - Full path without quotes
        .hash - MD5 of file at path

#>
$final = New-Object collections.arraylist $svcBlocc.Count
$svcBlocc | foreach {
    if (-not (test-path $_)) {
        [void]$final.Add(@{path=$_;hash="DNE"})
    }
    else {
        $tmp = (Get-FileHash -Algorithm MD5 -Path $_ | select Hash).Hash
        [void]$final.Add(@{path=$_;hash=$tmp})
    }
}
$final | foreach {
    if ($Outfile -eq "") {
        Write-Host ('"' + $_.path + '",' + $_.hash)
    }
    else {
        Add-Content -Path $Outfile -Value ('"' + $_.path + '",' + $_.hash)
    }
}
}

#UNCOMMENT THIS LINE AND LINE 8 IF YOU WANT TO CALL AS SCRIPT
#LEAVE THEM TO JUST IMPORT THE CMDLET
#Get-ServiceKeyHashes -Outfile $outpath
