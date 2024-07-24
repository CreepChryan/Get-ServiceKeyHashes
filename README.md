# Get-ServiceKeyHashes
Powershell function to hash windows service executables for hunting for MITRE code T1543.003

Gathers all the ImagePath values for each service in HKLM:\SYSTEM\CurrentControlSet\Services\ and generates an MD5 hash of the referenced files.
Outputs by default to STDOUT however can write to a file instead via the -Outfile parameter.
If a serivice's target has been deleted, moved, or otherwise could not be resolved it will still be outputted with a hash value of "DNE" or does not exist.
Written to be utilized as a function/CMDlet with proper output set up for Get-Help however by uncommenting lines 6 and 103 can be used as a regular script.

Handles entries with full absolute paths, partial paths starting in System32, and any references to the SystemRoot environmental variable, I'm unaware of any edge cases but potentially can add handling as they're brought to my attention.
