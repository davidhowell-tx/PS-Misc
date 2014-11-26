<# 
.SYNOPSIS 
    This script utilizes WMI to Remotely Enable or Disable PSRemoting

.PARAMETER ComputerName
    This parameter is used to define the remote computer name with which to interact.

.PARAMETER Disable
    This switch designates that the script should disable PowerShell remoting on the remote system.

.PARAMETER Enable
    This switch designates that the script should enable PowerShell remoting on the remote system.

.EXAMPLE
    Set-PSRemotingRemotely.ps1 -ComputerName SERVER001 -Enable

.EXAMPLE
    Set-PSRemotingRemotely.ps1 -ComputerName SERVER001 -Disable
#>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)][String]
        $ComputerName=$null,
    [Parameter(ParameterSetName='Disable')]
        [Switch]$Disable=$null,
    [Parameter(ParameterSetName='Enable')]
        [Switch]$Enable=$null
)

if ($Enable) {
    Invoke-WmiMethod -ComputerName $ComputerName -Class Win32_Process -Name Create -ArgumentList {powershell.exe -exec bypass -command "Enable-PSRemoting -Force"}
} elseif ($Disable) {
    Invoke-WmiMethod -ComputerName $ComputerName -Class Win32_Process -Name Create -ArgumentList {powershell.exe -exec bypass -command "Disable-PSRemoting -Force"}
}