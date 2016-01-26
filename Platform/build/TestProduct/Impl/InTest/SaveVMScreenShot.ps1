param 
(
    [Parameter(Position=0, Mandatory=$true)]$VMname,
    [Parameter(Position=0, Mandatory=$true)]$ViServerAddress,
    [Parameter(Position=0, Mandatory=$true)]$ViServerLogin,
    [Parameter(Position=0, Mandatory=$true)]$ViServerPasword,
    [Parameter(Position=0, Mandatory=$true)]$FileFolder
)

<#ScriptPrologue#> Set-StrictMode -Version Latest; $ErrorActionPreference = [System.Management.Automation.ActionPreference]::Stop
function Get-ScriptDirectory { Split-Path $script:MyInvocation.MyCommand.Path }
function GetDirectoryNameOfFileAbove($markerfile) { $result = ""; $path = $MyInvocation.ScriptName; while(($path -ne "") -and ($path -ne $null) -and ($result -eq "")) { if(Test-Path $(Join-Path $path $markerfile)) {$result=$path}; $path = Split-Path $path }; if($result -eq ""){throw "Could not find marker file $markerfile in parent folders."} return $result; }
$ProductHomeDir = GetDirectoryNameOfFileAbove "Product.Root"

function TakeScreenshot($VMname)
{
    $MoRef = (Get-VM $VMname).ExtensionData.MoRef.Value
    $urlpath  =  "https://$ViServerAddress/screen?id=$MoRef"

    $webclient = New-Object System.Net.WebClient
    $webclient.Credentials = new-object System.Net.NetworkCredential($ViServerLogin, $ViServerPasword)
    $date = Get-Date  -Format dd-MM-yyyy_hh-mm-ss
    $file = "$FileFolder\InstallationPS$date.png"
    write-host "trying to save png file: $file"
    Try
    {
        $webclient.DownloadFile($urlpath ,$file)
        write-host "##teamcity[publishArtifacts '$file']"
    }
    Catch
    {
        Write-Error "Error! trying to save png file: $file"
        Write-Error ($_.Exception)
    }
    
}

function Run()
{
    & (Join-Path (Get-ScriptDirectory) "ViServer.Connect.ps1") -ViServerAddress $ViServerAddress -ViServerLogin $ViServerLogin -ViServerPasword $ViServerPasword | Out-Null

    $vms = @(Get-VM -Name $VMname*)
    foreach ($vm in $vms)
    {
        TakeScreenshot $vm
    }
    DisconnectAll
}

function DisconnectAll()
{
    Disconnect-VIServer -Server * -Force -Confirm:$false
}

Run
