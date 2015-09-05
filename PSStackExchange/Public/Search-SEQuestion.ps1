Function Search-SEQuestion {
    <#
    .SYNOPSIS
        Search a StackExchange site for questions
    
    .DESCRIPTION
        Search a StackExchange site for questions

    .PARAMETER Title
        Text which must appear in returned questions' titles
    
    .PARAMETER Site
        StackExchange site. Default is stackoverflow

    .PARAMETER Tag
        Search by tag

        Limited to 5 tags

    .PARAMETER ExcludeTag
        Exclude questions with these tags

        Limited to 5 tags

    .PARAMETER BodyText
        Text which must appear in returned questions' bodies
    
    .PARAMETER Closed
        True to return only closed questions, false to return only open ones.

    .PARAMETER Answers
        The minimum number of answers returned questions must have

    .PARAMETER Accepted
        True to return only questions with accepted answers, false to return only those without.

    .PARAMETER Views
        The minimum number of views returned questions must have

    .PARAMETER Text
        A free form text parameter, will match all question properties based on an undocumented algorithm

    .PARAMETER User
        The id of the user who must own the questions returned

    .PARAMETER URL 
        A url which must be contained in a post, may include a wildcard

    .PARAMETER Order
        Ascending or Descending

    .PARAMETER Sort
        Sorting method:
            activity:  last_activity_date
            creation:  creation_date
            votes:     score
            relevance: matches the relevance tab on the site itself

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

    .FUNCTIONALITY
        StackExchange

    .LINK
        https://github.com/RamblingCookieMonster/PSStackExchange

    .LINK
        https://api.stackexchange.com/docs/advanced-search

    #>
    [cmdletbinding()]
    param(
        [string]$Title,
        [string]$Site = 'stackoverflow',
        [ValidateCount(0,5)]
        [string[]]$Tag,
        [ValidateCount(0,5)]
        [string[]]$ExcludeTag,
        [string]$BodyText,
        [bool]$Closed,
        [int]$Answers,
        [bool]$Accepted,
        [int]$Views,
        [string]$Text,
        [string]$User,
        [string]$URL,
        [datetime]$FromDate,
        [datetime]$ToDate,
        [ValidateSet('asc', 'desc')]
        [string]$Order,
        [ValidateSet('Activity', 'Creation', 'Votes', 'Relevance')]
        [string]$Sort,
        [string]$Uri = 'https://api.stackexchange.com',
        [string]$Version = "2.2",
        [ValidateRange(1,100)][int]$PageSize = 30,
        [int]$MaxResults = 100,        
        [Hashtable]$Body = @{},
        [switch]$Raw
    )

    # This code basically wraps a call to Get-SEObject function
    # Build up the URI
        [string]$Object = "search/advanced"
    
    # Build up the CGI
    # We override existing items in body
        if($Title) { $Body.title = $Title }
        if($Tag) { $Body.tagged = $Tag -Join ';' }
        if($ExcludeTag) { $Body.nottagged = $ExcludeTag -Join ';' }
        if($Text) { $Body.q = $Text }
        if($User) { $Body.user = $User }
        if($BodyText) {$Body.body = $BodyText}
        if($URL) { $Body.url = $URL }
        if($FromDate) { $Body.FromDate = ConvertTo-UnixDate -Date $FromDate}
        if($ToDate) { $Body.ToDate = ConvertTo-UnixDate -Date $ToDate }
        if($PSBoundParameters.ContainsKey('accepted')) { $Body.accepted = $Accepted }
        if($PSBoundParameters.ContainsKey('answers')) { $Body.answers = $Answers }
        if($PSBoundParameters.ContainsKey('closed')) { $Body.closed = $Closed }
        if($PSBoundParameters.ContainsKey('views ')) { $Body.views  = $views  }
        if($PSBoundParameters.ContainsKey('closed')) { $Body.closed = $Closed }

        if($Sort) { $Body.Sort = $Sort }
        if($Order){ $Body.Order = $Order }
        $Body.site = $Site

    # Build up Get-StackObject parameters
        $GSOParams = @{
            Object = $Object
            Uri = $Uri
            Version = $Version
            Pagesize = $PageSize
            MaxResults = $MaxResults
        }
        if($Body.Keys.Count -gt 0) {$GSOParams.Body = $Body }
        if($Raw) {$GSOParams.Raw = $True}

    Write-Debug ( "Running $($MyInvocation.MyCommand).`n" +
                    "PSBoundParameters:`n$($PSBoundParameters | Format-List | Out-String)" +
                    "Get-SEObject parameters:`n$($GSOParams | Format-List | Out-String)" )


    Try
    {
        #Get the data from StackExchange
        Get-SEObject @GSOParams
    }
    Catch
    {
        Throw $_
    }
}