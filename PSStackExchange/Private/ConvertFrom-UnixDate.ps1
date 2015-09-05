Function ConvertFrom-UnixDate {
    <#
    .SYNOPSIS
        Convert from Unix time to DateTime

    .DESCRIPTION
        Convert from Unix time to DateTime

    .PARAMETER Date
        Date to convert, in Unix / Epoch format

    .PARAMETER Utc
        Default behavior is to convert Date to universal time.

        Set this to false to return local time.

    .EXAMPLE
        ConvertFrom-UnixDate -Date 1441471257

    .FUNCTIONALITY
        General Command
    #>
    Param(
        [int]$Date,
        [bool]$Utc = $true
    )

    # Adapted from http://stackoverflow.com/questions/10781697/convert-unix-time-with-powershell
    $unixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)
    $Output = $unixEpochStart.AddSeconds($Date)

    if(-not $utc)
    {
        $Output = $Output.ToLocalTime()
    }

    $Output
}