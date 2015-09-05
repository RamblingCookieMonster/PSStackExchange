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
        The base Uri for the StackExchange API.
        
        Default: https://api.stackexchange.com

    .PARAMETER Version
        The StackExchange API version to use.

    .PARAMETER PageSize
        Items to retrieve per query

    .PARAMETER MaxResults
        Maximum number of items to return

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

    .EXAMPLE
        Get-SEObject Sites 

        # List sites on StackExchange

    .EXAMPLE
        Get-SEObject -Object questions/unanswered -MaxResults 50 -Body @{
            site='stackoverflow'
            tagged='powershell'
            order='desc'
            sort='creation'
        }

        # Get the most recent 50 unanswered questions from stackoverflow, tagged powershell

    .FUNCTIONALITY
        StackExchange
    #>
    [cmdletbinding()]
    param(    
        [string]$Object = "questions",
        [string]$Uri = 'https://api.stackexchange.com',
        [string]$Version = "2.2",
        [validaterange(1,100)][int]$PageSize = 30,
        [int]$MaxResults = [int]::MaxValue,        
        [Hashtable]$Body,
        [switch]$Raw
    )

    #This code basically wraps a call to the private Get-SEData function

    #Build up URI
        $BaseUri = Join-Parts -Separator "/" -Parts $Uri, $Version, $($object.ToLower())

    #Build up Invoke-RestMethod and Get-SEData parameters for splatting
        $IRMParams = @{
            ErrorAction = 'Stop'
            Uri = $BaseUri
            Method = 'Get'
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

        $GSDParams = @{ 
            IRMParams = $IRMParams
            MaxResults = $MaxResults    
        }
        if($PSBoundParameters.ContainsKey('Raw'))
        {
            $GSDParams.Add( 'Raw', $Raw )
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
}