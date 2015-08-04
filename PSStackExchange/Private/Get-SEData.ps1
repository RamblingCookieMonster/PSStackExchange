<#
    Helper function to abstract out paging and extraction of 'items'
#>

function Get-SEData
{
    [cmdletbinding()]
    param (
        $IRMParams,
        [switch]$Raw,
        $UseIWR,
        [int]$Pagesize,
        [int]$Page = 1,
        [int]$MaxResults = 50
    )

    #Keep track of how many items we pull...
    [int]$ResultsSoFar = 0
    
    do
    {
        #Init page and pagesize
        if(-not $IRMParams.Body.ContainsKey('page'))
        {
            $IRMParams.Body.page = $Page
        }
        
        #Don't reset pagesize if we set it as a remainder...
        if($IRMParams.Body.ContainsKey('PageSize') -and $Pagesize)
        {
            # Override with the param, or a MaxResults - ResultSoFar remainder
            $IRMParams.Body.Pagesize = $Pagesize
        }
        elseif($IRMParams.Body.ContainsKey('PageSize'))
        {
            #Normal. Pagesize was specified. Pull it out for simplicity.
            $Pagesize = $IRMParams.Body.Pagesize
        }
        elseif(-not $Pagesize)
        {
            #Weird. No pagesize or body pagesize set. Set it to 30.
            $Pagesize = 30
            $IRMParams.Body.Pagesize = $Pagesize
        }
        
        Try
        {
            $Err = $null
            write-debug "Final $($IRMParams | Out-string) Body $($IRMParams.Body | Out-String)"
            
            #We might want to track the HTTP status code to verify success for non-gets...
            if($UseIWR)
            {   
                $TempResult = Invoke-WebRequest @IRMParams
            }
            else
            {
                $TempResult = Invoke-RestMethod @IRMParams -ErrorVariable Err
            }
            Write-Debug "Raw:`n$($TempResult | Out-String)"
        }
        Catch
        {
            Throw $_
        }
        
        if($Raw)
        {
            $TempResult
        }
        elseif($TempResult.PSObject.Properties.Name -contains 'items')
        {
            $TempResult.items
        }
        else
        {
            $TempResult
        }

        #How many results have we seen?
        [int]$ResultsSoFar += $Pagesize
        $Page++

        #Wow, forgot how painful math was...
        Write-Debug "
        ResultsSoFar = $ResultsSoFar
        PageSize = $PageSize
        Page++ = $Page
        MaxResults = $MaxResults
        (ResultsSoFar + PageSize) -gt MaxResults $(($ResultsSoFar + $PageSize) -gt $MaxResults)
        ResultsSoFar -ne MaxResults $($ResultsSoFar -ne $MaxResults)
        "

        #Will the next loop put us over? Get the remainder and set it as pagesize
        if(($ResultsSoFar + $PageSize) -ge $MaxResults -and $ResultsSoFar -ne $MaxResults)
        {
            $PageSize = $MaxResults - $ResultsSoFar
            Write-Debug "PageSize Change to $PageSize"
        }

        #Loop readout
        Write-Debug "TempResult.has_more: $($TempResult.has_more)Raw: $Raw`n Not TempResult.items = $(-not $TempResult.items)`n ResultSoFar -gt MaxResults: $ResultsSoFar -gt $MaxResults"
    }
    until (
        -not $TempResult.has_more -or
        $Raw -or 
        -not $TempResult.items -or
        $ResultsSoFar -ge $MaxResults
    )
}