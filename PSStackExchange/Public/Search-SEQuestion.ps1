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

    .PARAMETER FromDate
        Return only questions posted after this date

    .PARAMETER ToDate
        Return only questions posted before this date

    .PARAMETER Order
        Ascending or Descending

    .PARAMETER Sort
        Sorting method:
            activity:  last_activity_date
            creation:  creation_date
            votes:     score
            relevance: matches the relevance tab on the site itself

    .PARAMETER Uri
        The base Uri for the StackExchange API.

        Default: https://api.stackexchange.com

    .PARAMETER Version
        The StackExchange API version to use.

    .PARAMETER PageSize
        Items to retrieve per query. Defaults to 30

    .PARAMETER MaxResults
        Maximum number of items to return. Defaults to 100

        Specify $null or 0 to set this to the maximum value

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

    .FUNCTIONALITY
        StackExchange

    .EXAMPLE
        Search-SEQuestion -Title Citrix -Tag PowerShell

        # Search for questions with Citrix in the title
        #    Posted on stackoverflow (default)
        #    Tagged PowerShell

    .EXAMPLE
        Search-SEQuestion -User 105072 ` 
                          -Site ServerFault ` 
                          -ExcludeTag 'windows-server-2008-r2' ` 
                          -Title PowerShell

        # Search for questions from ServerFault User with ID 105072
        #    On the ServerFault site
        #    Excluding anything tagged with server 2008 r2
        #    Including items with PowerShell in the title

    .EXAMPLE
        Search-SEQuestion -URL *github.com/RamblingCookieMonster/*

        # Search for questions including the partial URL github.com/RamblingCookieMonster/
        #    Posted on stackoverflow (default)

        # If you post code on the internet, this is a great way to see if folks are having trouble with it

    .EXAMPLE
        Search-SEQuestion -Tag PowerShell -Accepted $False -Sort Creation -MaxResults 20 |
            Out-GridView -PassThru |
            Foreach {
                & 'C:\Program Files\Internet Explorer\iexplore.exe' $_.link
            }
        
        # Search for questions tagged PowerShell
        #    Posted on stackoverflow (default)
        #    That do not have an accepted answer
        #    sorted by creation date
        #    Limited to the first 20 results
        #    Send output to a gridview
        #    Open the selected questions in IE

    .EXAMPLE
        Search-SEQuestion -Title 'system.dbnull' -tag powershell | Get-SEAnswer

        # Search for a question tagged PowerShell, with System.DBNull in the title
        # Get the answers for any questions that come back

    .LINK
        http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module

    .LINK
        https://github.com/RamblingCookieMonster/PSStackExchange

    .LINK
        https://api.stackexchange.com/docs/advanced-search

    .LINK
        https://api.stackexchange.com/docs/questions

    .LINK
        Get-SEAnswer

    .LINK
        Get-SEQuestion

    .LINK
        Get-SEObject

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
        [Hashtable]$Body = @{}
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

    Write-Debug ( "Running $($MyInvocation.MyCommand).`n" +
                    "PSBoundParameters:`n$($PSBoundParameters | Format-List | Out-String)" +
                    "Get-SEObject parameters:`n$($GSOParams | Format-List | Out-String)" )


    Try
    {
        #Get the data from StackExchange
        Get-SEObject @GSOParams | ForEach-Object {

            #Add formatting and convert dates to expected format
            Add-ObjectDetail -InputObject $_ -TypeName 'PSStackExchange.Question' -PropertyToAdd @{
                CreationDate = ConvertFrom-UnixDate -Date $_.creation_date
                LastActivityDate = ConvertFrom-UnixDate -Date $_.last_activity_date
                LastEditDate = ConvertFrom-UnixDate -Date $_.last_edit_date
                SESite = $Site
            }
        }    
    }
    Catch
    {
        Throw $_
    }
}