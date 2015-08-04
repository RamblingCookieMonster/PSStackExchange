Function Get-SEObject {
    <#
    .SYNOPSIS
        Get a specified object from StackExchange
    
    .DESCRIPTION
        Get a specified object from StackExchange

    .PARAMETER Object
        Type of object to query for. Accepts multiple parts.
        
        Example: 'sites' or 'questions/unanswered'

    .PARAMETER Uri
        The base Uri for StackExchange.
        
        Default: https://api.stackexchange.com

    .PARAMETER Body
        Hash table with query options for specific object

        These don't appear to be case sensitive

        Example for recent powershell activity:
            -Body @{
                site  =  'stackoverflow'
                tagged = 'powershell'
                order =  'desc'
                sort =   'activity'
            }

    .PARAMETER Raw
        If specified, do not extract the 'Items' attribute of the results.

    .PARAMETER Credential
        A valid PSCredential

    .EXAMPLE
        Get-StashObject -Object projects 

        #List public projects on Stash, using the URI from Get-StashConfig/Set-StashConfig

    .EXAMPLE
        Get-StashObject -Object projects/sysinv/repos -Credential $Cred 

        # List repositories under the 'sysinv' project on Stash...
        # Authenticates with $Cred
        # Uses the URI from Get-StashConfig/Set-StashConfig

    .EXAMPLE
        Get-StashObject -Object projects -Uri http://stash.contoso.com

        # List public projects on Stash at http://stash.contoso.com

    .EXAMPLE
        Get-StashObject -Object repos -body @{name='r'} -Credential $cred

        # Find repositories that start with the letter r

    .EXAMPLE
        Get-StashObject -Object groups -body @{filter='stash'} -Credential $cred

        # Find groups with the string 'stash' in their name

    .FUNCTIONALITY
        Stash
    #>
    [cmdletbinding()]
    param(    
        [string]$Object = "questions",
        
        [string]$Uri = 'https://api.stackexchange.com',
        
        [string]$Version = "2.0",
        
        [int]$PageSize = 30,
        
        [int]$MaxResults,
        
        [System.Management.Automation.PSCredential]$Credential,
        
        [Hashtable]$Body,
        
        [switch]$Raw
    )

    #Build up URI
        $BaseUri = Join-Parts -Separator "/" -Parts $Uri, $Version, $($object.ToLower())

    #Build up Invoke-RestMethod and Get-StashData parameters for splatting
        $IRMParams = @{
            ErrorAction = 'Stop'
            Uri = $BaseUri
            Method = 'Get'
        }
        if($PSBoundParameters.ContainsKey('Credential'))
        {
            #$IRMParams.Add( 'Headers', @{ Authorization = (Get-StashAuthString -Credential $Credential) } )
        }
        if($PSBoundParameters.ContainsKey('Body'))
        {
            if(-not $Body.Keys -contains 'pagesize')
            {
                $Body.pagesize = $PageSize
            }
            $IRMParams.Add( 'Body', $Body )
        }
        else
        {
            $IRMParams.Add('Body',@{pagesize = $PageSize})
        }

        $GSDParams = @{ IRMParams = $IRMParams }
        if($PSBoundParameters.ContainsKey('Raw'))
        {
            $GSDParams.Add( 'Raw', $Raw )
        }
        if($PSBoundParameters.ContainsKey('MaxResults'))
        {
            $GSDParams.Add( 'MaxResults', $MaxResults )
        }

    Write-Debug ( "Running $($MyInvocation.MyCommand).`n" +
                    "PSBoundParameters:$( $PSBoundParameters | Format-List | Out-String)" +
                    "Invoke-RestMethod parameters:`n$($IRMParams | Format-List | Out-String)" +
                    "Get-SEData parameters:`n$($GSDParams | Format-List | Out-String)" )

    Try
    {
        #Get the data from Stash
        Get-SEData @GSDParams
    }
    Catch
    {
        Throw $_
    }

    Remove-Variable IRMParams -force -ErrorAction SilentlyContinue
}