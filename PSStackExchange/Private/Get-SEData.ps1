function Get-SEData
{
    [cmdletbinding()]
    param (
        $IRMParams,
        [switch]$Raw,
        $UseIWR,
        $Page = 1,
        $PageSize,
        $MaxSize = 100
    )
    
    $Uri = $IRMParams.Uri

    #Start at page
    #Increment page

    do
    {
        if($Page -eq 1)
        {
            if(-not $IRMParams.containskey('Body'))
            {
                $IRMParams.Add( 'Body', @{} )
            }
            $IRMParams.Body.page = $Page
            $IRMParams.Body.pagesize = $PageSize
        }
        else
        {
            $IRMParams.Body.page = $IRMParams.Body.page + 1
        }

        Try
        {
            $Err = $null
            write-debug "Final $($IRMParams | Out-string)"
            
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

    }
    until (
        -not $TempResult.has_more -or
        $Raw -or 
        -not $TempResult.items -or
        ($PageSize * ($Page + 1)) -gt $MaxSize
    )
}