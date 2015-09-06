Function Get-SEAnswer {
    <#
    .SYNOPSIS
        Get answers from StackExchange

    .DESCRIPTION
        Get answers from StackExchange

    .PARAMETER Site
        StackExchange site to get questions from. Default is stackoverflow

    .PARAMETER QuestionID
        If specified, find answers from this specific question ID

    .PARAMETER FromDate
        Return only answers posted after this date

    .PARAMETER ToDate
        Return only answers posted before this date

    .PARAMETER Order
        Ascending or Descending

    .PARAMETER Sort
        Sorting method:
            activity
            creation
            votes

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

        Example for recent activity:
            -Body @{
                site  =  'stackoverflow'
                order =  'desc'
                sort =   'activity'
            }

    .FUNCTIONALITY
        StackExchange

    .EXAMPLE
        Get-SEAnswer -Site ServerFault -MaxResults 1

        # Get a single answer from ServerFault

    .EXAMPLE
        Get-SEAnswer -Site ServerFault -MaxResults 1 |
            Select -Property *

        # Get a single answer from ServerFault, view extended properties:

    .EXAMPLE
        Search-SEQuestion -Title 'system.dbnull' -tag powershell | Get-SEAnswer

        # Search for a question tagged PowerShell, with System.DBNull in the title
        # Get the answers for any questions that come back

    .LINK
        http://ramblingcookiemonster.github.io/Building-A-PowerShell-Module

    .LINK
        https://github.com/RamblingCookieMonster/PSStackExchange

    .LINK
        https://api.stackexchange.com/docs/answers

    .LINK
        Get-SEQuestion

    .LINK
        Search-SEQuestion

    .LINK
        Get-SEObject
    #>
    [cmdletbinding()]
    param(
        [parameter(ValueFromPipelineByPropertyName = $True)]
        [alias('SESite')]
        [string]$Site = 'stackoverflow',
        [parameter(ValueFromPipelineByPropertyName = $True)]
        [alias('question_id')]
        [int[]]$QuestionID,
        [datetime]$FromDate,
        [datetime]$ToDate,
        [ValidateSet('asc', 'desc')]
        [string]$Order,
        [ValidateSet('Activity', 'Creation', 'Votes')]
        [string]$Sort,
        [string]$Uri = 'https://api.stackexchange.com',
        [string]$Version = "2.2",
        [ValidateRange(1,100)][int]$PageSize = 30,
        [int]$MaxResults = 100,
        [Hashtable]$Body = @{}
    )
    Process
    {
        # This code basically wraps a call to the private Get-SEData function
        
        # Build up the URI
            if($PSBoundParameters.ContainsKey('QuestionID'))
            {
                $QuestionID = $QuestionID -join ';'
                [string]$Object = "questions/$QuestionID/answers"
            }
            else
            {
                [string]$Object = 'answers'
            }
            
        # Build up the CGI
        # We override existing items in body
            if($Sort) { $Body.Sort = $Sort }
            if($Order) { $Body.Order = $Order }
            if($FromDate) { $Body.FromDate = ConvertTo-UnixDate -Date $FromDate}
            if($ToDate) { $Body.ToDate = ConvertTo-UnixDate -Date $ToDate }
            if($Site) { $Body.site = $Site }
            $Body.Filter = '!-*f(6sCN5zee' # This pre-calculated filter adds body and link properties

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
                Add-ObjectDetail -InputObject $_ -TypeName 'PSStackExchange.Answer' -PropertyToAdd @{
                    CreationDate = ConvertFrom-UnixDate -Date $_.creation_date
                    LastActivityDate = ConvertFrom-UnixDate -Date $_.last_activity_date
                }
            }     
        }
        Catch
        {
            Throw $_
        }
    }
}