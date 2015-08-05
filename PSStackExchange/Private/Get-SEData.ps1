<#
    Helper function to abstract out paging and extraction of 'items'
        API docs:       https://api.stackexchange.com/docs
        Paging details: https://api.stackexchange.com/docs/paging
#>

function Get-SEData
{
    [cmdletbinding()]
    param (
        $IRMParams,
        [switch]$Raw,
        [int]$Pagesize,
        [int]$Page = 1,
        [int]$MaxResults
    )

    #Keep track of how many items we pull...
    [int]$ResultsSoFar = 0
    
    do
    {
        # If user specified page, and not first loop, don't touch it. Otherwise, set it!
        if(-not ($ResultsSoFar -eq 0 -and -not $IRMParams.ContainsKey('page')))
        {
            $IRMParams.Body.page = $Page
        }
        
        #init pagesize
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
        
        #Collect the results
        Try
        {
            write-debug "Final $($IRMParams | Out-string) Body $($IRMParams.Body | Out-String)"
            
            #We might want to track the HTTP status code to verify success for non-gets...
            $TempResult = Invoke-RestMethod @IRMParams
            
            Write-Debug "Raw:`n$($TempResult | Out-String)"
        }
        Catch
        {
            Throw $_
        }
        
        # raw, extract items, or... unexpected (no items prop)
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
            ResultsSoFar -ne MaxResults $($ResultsSoFar -ne $MaxResults)"

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
        $TempResult.has_more -ne $true -or
        $Raw -or
        -not $TempResult.items -or
        $ResultsSoFar -ge $MaxResults
    )
}