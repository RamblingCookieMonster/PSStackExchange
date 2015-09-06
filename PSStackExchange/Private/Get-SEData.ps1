<#
    Helper function to abstract out paging and extraction of 'items'
        API docs:       https://api.stackexchange.com/docs
        Paging details: https://api.stackexchange.com/docs/paging

    Note: Explicitly removed functionality to limit pagesize on final call based on MaxResults.
          If the pagesize is changed, it breaks paging / sorting
#>

function Get-SEData
{
    [cmdletbinding()]
    param (
        $IRMParams,
        [int]$Pagesize = 30,
        [int]$Page = 1,
        [int]$MaxResults
    )

    #Keep track of how many items we pull...
    [int]$ResultsSoFar = 0

    do
    {
        # If user specified page, and not first loop, don't touch it. Otherwise, set it!
        if(-not ($ResultsSoFar -eq 0 -and $IRMParams.ContainsKey('page')))
        {
            $IRMParams.Body.page = $Page
        }

        #init pagesize
        if($IRMParams.Body.ContainsKey('PageSize'))
        {
            #Normal. Pagesize was specified. Pull it out for simplicity.
            $Pagesize = $IRMParams.Body.pagesize
        }
        else
        {
            #Something odd happened. Pagesize should have been specified.
            $IRMParams.Body.pagesize = $Pagesize
        }

        # First run and maxresults is lower than pagesize? Overruled!
        if($ResultsSoFar -eq 0 -and $Pagesize -gt $MaxResults)
        {
            $IRMParams.Body.pagesize = $Pagesize = $MaxResults
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

        if($TempResult.PSObject.Properties.Name -contains 'items')
        {
            $TempResult.items
        }
        else # what is going on!
        {
            $TempResult
        }

        #How many results have we seen?
        [int]$ResultsSoFar += $Pagesize
        $Page++

        Write-Debug "
            ResultsSoFar = $ResultsSoFar
            PageSize = $PageSize
            Page++ = $Page
            MaxResults = $MaxResults
            (ResultsSoFar + PageSize) -gt MaxResults $(($ResultsSoFar + $PageSize) -gt $MaxResults)
            ResultsSoFar -ne MaxResults $($ResultsSoFar -ne $MaxResults)"

        #Loop readout
        Write-Debug "TempResult.has_more: $($TempResult.has_more)`n Not TempResult.items = $(-not $TempResult.items)`n ResultSoFar -gt MaxResults: $ResultsSoFar -gt $MaxResults"
    }
    until (
        $TempResult.has_more -ne $true -or
        -not $TempResult.items -or
        $ResultsSoFar -ge $MaxResults
    )
}