Function Get-SEQuestion {
    <#
    .SYNOPSIS
        Get questions from StackExchange

    .DESCRIPTION
        Get questions from StackExchange

    .PARAMETER Site
        StackExchange site to get questions from. Default is stackoverflow

    .PARAMETER Tag
        Search by tag

        Limited to 5 tags

    .PARAMETER Unanswered
        Return only questions not marked as answered

    .PARAMETER NoAnswers
        Return only questions with no answers

    .PARAMETER Featured
        Return only featured questions

    .PARAMETER FromDate
        Return only questions posted after this date

    .PARAMETER ToDate
        Return only questions posted before this date

    .PARAMETER Order
        Ascending or Descending

    .PARAMETER Sort
        Sorting method:
            activity
            creation
            votes
            hot
            week
            month

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

    .EXAMPLE
        Get-SEObject Sites

        # List sites on StackExchange

    .EXAMPLE
        Get-SEQuestion -UnAnswered -Tag PowerShell -FromDate $(Get-Date).AddDays(-1) -Site ServerFault

        # Get unanswered questions...
        #    Tagged PowerShell...
        #    From the past day...
        #    From the ServerFault site

    .EXAMPLE
        Get-SEQuestion -Featured -Tag PowerShell -Site StackOverflow -MaxResults 20

        # Get featured questions...
        #    Tagged PowerShell...
        #    From the stackoverflow site
        #    Limited to 20 items

    .FUNCTIONALITY
        StackExchange

    .LINK
        http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module

    .LINK
        https://github.com/RamblingCookieMonster/PSStackExchange

    .LINK
        https://api.stackexchange.com/docs/questions

    .LINK
        Get-SEAnswer

    .LINK
        Search-SEQuestion

    .LINK
        Get-SEObject
    #>
    [cmdletbinding()]
    param(
        [switch]$UnAnswered,
        [switch]$Featured,
        [switch]$NoAnswers,
        [string]$Site = 'stackoverflow',
        [ValidateCount(0,5)]
        [string[]]$Tag,
        [datetime]$FromDate,
        [datetime]$ToDate,
        [ValidateSet('asc', 'desc')]
        [string]$Order,
        [ValidateSet('Activity', 'Creation', 'Votes', 'Hot', 'Week', 'Month')]
        [string]$Sort,
        [string]$Uri = 'https://api.stackexchange.com',
        [string]$Version = "2.2",
        [ValidateRange(1,100)][int]$PageSize = 30,
        [int]$MaxResults = 100,
        [Hashtable]$Body = @{}
    )

    # This code basically wraps a call to the private Get-SEData function
    # Build up the URI
        [string]$Object = "questions"
        if     ($Unanswered) { $Object = Join-Parts -Separator '/' -Parts $Object/unanswered }
        elseif ($Featured)   { $Object = Join-Parts -Separator '/' -Parts $Object/Featured   }
        elseif ($NoAnswers)  { $Object = Join-Parts -Separator '/' -Parts $Object/no-answers }

    # Build up the CGI
    # We override existing items in body
        if($Tag) { $Body.Tagged = $Tag -Join ';' }
        if($Sort) { $Body.Sort = $Sort }
        if($Order) { $Body.Order = $Order }
        if($FromDate) { $Body.FromDate = ConvertTo-UnixDate -Date $FromDate}
        if($ToDate) { $Body.ToDate = ConvertTo-UnixDate -Date $ToDate }
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