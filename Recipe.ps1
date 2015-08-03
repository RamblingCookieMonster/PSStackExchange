# We cloned our project to C:\sc\PSStackExchange
$Path = 'C:\sc\PSStackExchange'
$ModuleName = 'PSStackExchange'
$Author = 'RamblingCookieMonster'
$Description = 'PowerShell module to query the StackExchange API'

# Create the module and private function directories
mkdir $Path\$ModuleName
mkdir $Path\Private

#Create the script module and module manifest
New-Item "$Path\$ModuleName\$ModuleName.psm1" -ItemType File
New-Item "$Path\$ModuleName\$ModuleName.Format.ps1xml" -ItemType File
New-ModuleManifest -Path $Path\$ModuleName\$ModuleName.psd1 `
                   -RootModule $Path\$ModuleName\$ModuleName.psm1 `
                   -Description $Description `
                   -PowerShellVersion 3.0 `
                   -Author $Author `
                   -FormatsToProcess "$ModuleName.Format.ps1xml"

# Copy the public functions into the module folder, private functions into private folder
