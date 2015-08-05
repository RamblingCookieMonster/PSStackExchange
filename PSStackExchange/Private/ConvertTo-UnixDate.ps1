Function ConvertTo-UnixDate {
    <#
    .SYNOPSIS
        Convert from DateTime to Unix date

    .DESCRIPTION
        Convert from DateTime to Unix date

    .PARAMETER Date
        Date to convert

    .PARAMETER Utc
        Default behavior is to convert Date to universal time.  Set this to false to skip this step.

    .EXAMPLE
        ConvertTo-UnixDate -Date (Get-date)

    .FUNCTIONALITY
        General Command
    #>
    Param(
        [datetime]$Date = (Get-Date),
        [bool]$Utc = $true
    )

    #Borrowed from the internet, presumably.

    if($utc)
    {
        $Date = $Date.ToUniversalTime()
    }

    $unixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
    [int]($Date - $unixEpochStart).TotalSeconds
}