$Verbose = @{}
if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
{
    $Verbose.add("Verbose",$True)
}

$PSVersion = $PSVersionTable.PSVersion.Major
Import-Module $PSScriptRoot\..\PSStackExchange -Force

#Integration test example
<# Describe "Get-SEObject PS$PSVersion Integrations tests" {

    Context 'Strict mode' { 

        Set-StrictMode -Version latest

        It 'should get valid data' {
            $Output = Get-SEObject -Object sites
            $Output.count -gt 100 | Should be $True
            $Output.name -contains 'stack overflow'
        }
    }
}
#>
$Global:blah = $null
#Unit test example
Describe "Get-SEObject PS$PSVersion Unit tests" {

    Mock -ModuleName PSStackExchange -CommandName Get-SEData { $Args }
    Context 'Strict mode' {

        Set-StrictMode -Version latest

        It 'should call Get-SEData' {
            $Output = Get-SEObject -Object sites
            $Global:Blah = $Output
            Assert-MockCalled -CommandName Get-SEData -Scope It -ModuleName PSStackExchange
        }

        It 'should pass the right arguments to Get-SEData' {
            $Output = Get-SEObject -Object sites
            
            # Verify Maxresults
            $Output[3] | Should Be ([int]::MaxValue)

            # Verify IRMParams
            # Hard coding this expected value is delicate, will break if default URI or Version parameter values change
            $Output[1].Uri | Should Be 'https://api.stackexchange.com/2.2/sites'

            $Output[1].Body.Pagesize | Should Be 30
        }

    }
}
